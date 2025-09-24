from datetime import timedelta
from io import BytesIO

from django.db.models import Count, Sum, Avg
from django.db.models.functions import TruncDay, TruncWeek, TruncMonth
from django.shortcuts import get_object_or_404
from django.http import HttpResponse, FileResponse

from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from reportlab.pdfgen import canvas
import pandas as pd
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import inch

from bookings.models import Tenant, Booking


class TenantKPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, tenant_id):
        tenant = get_object_or_404(Tenant, id=tenant_id)
        carwashes = tenant.carwashes.all()

        result = []

        for carwash in carwashes:
            bookings = Booking.objects.filter(tenant=tenant, carwash=carwash)

            if not bookings.exists():
                continue

            latest_booking = bookings.latest('created_at')
            today = latest_booking.created_at.date() if latest_booking.created_at else None
            if not today:
                continue

            total_bookings = bookings.count()
            total_income = bookings.aggregate(total=Sum('amount'))['total'] or 0
            arpw = total_income / total_bookings if total_bookings else 0

            daily_sales = bookings.annotate(day=TruncDay('created_at')) \
                                  .values('day') \
                                  .annotate(total=Sum('amount'), count=Count('id')) \
                                  .order_by('day')

            unique_customers = bookings.values('phone_number').distinct().count()
            repeat_customers = bookings.values('phone_number') \
                                       .annotate(c=Count('id')) \
                                       .filter(c__gt=1).count()
            avg_visits = total_bookings / unique_customers if unique_customers else 0
            repeat_rate = (repeat_customers / unique_customers * 100) if unique_customers else 0

            past_30_days = today - timedelta(days=30)
            current_customers = bookings.filter(created_at__gte=past_30_days) \
                                        .values('phone_number').distinct().count()
            past_customers = bookings.filter(created_at__lt=past_30_days) \
                                     .values('phone_number').distinct().count()
            retention = (current_customers / past_customers * 100) if past_customers else 0

            most_booked_service = (
                bookings.values('service__name')
                        .annotate(count=Count('id'))
                        .order_by('-count')
                        .first()
            )
            most_booked_service_name = most_booked_service['service__name'] if most_booked_service else None

            online = bookings.filter(booking_source='online')
            walkin = bookings.filter(booking_source='walk_in')

            result.append({
                "carwash_id": carwash.id,
                "carwash_name": carwash.name,
                "total_bookings": total_bookings,
                "total_income": round(total_income, 2),
                "arpw": round(arpw, 2),
                "daily_sales": list(daily_sales),
                "customer_analytics": {
                    "unique_customers": unique_customers,
                    "repeat_customer_rate": round(repeat_rate, 2),
                    "avg_visit_frequency": round(avg_visits, 2),
                    "retention_rate": round(retention, 2),
                },
                "most_booked_service": most_booked_service_name,
                "booking_source_distribution": {
                    "online": {
                        "count": online.count(),
                        "revenue": round(online.aggregate(total=Sum('amount'))['total'] or 0, 2)
                    },
                    "walk_in": {
                        "count": walkin.count(),
                        "revenue": round(walkin.aggregate(total=Sum('amount'))['total'] or 0, 2)
                    }
                }
            })

        return Response({
            "tenant_id": tenant.id,
            "tenant_name": tenant.name,
            "carwash_analytics": result
        })

class TenantCarwashKPIExportPDFView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, tenant_id):
        tenant = get_object_or_404(Tenant, id=tenant_id)
        carwashes = tenant.carwashes.all()

        buffer = BytesIO()
        p = canvas.Canvas(buffer, pagesize=A4)
        width, height = A4
        x_margin = 50
        y = height - inch

        # Title
        p.setFont("Helvetica-Bold", 16)
        p.drawString(x_margin, y, f"KPI Comparison Report for Tenant: {tenant.name}")
        y -= 0.5 * inch

        # Table headers
        p.setFont("Helvetica-Bold", 10)
        headers = [
            "Carwash", "Bookings", "Income", "ARPW", "Unique", "Repeat", "Repeat Rate", 
            "Top Service", "Online", "Walk-in"
        ]
        col_widths = [90, 50, 55, 45, 50, 45, 60, 70, 45, 45]
        x_positions = [x_margin]
        for width_val in col_widths[:-1]:
            x_positions.append(x_positions[-1] + width_val)

        for i, header in enumerate(headers):
            p.drawString(x_positions[i], y, header)
        y -= 0.3 * inch
        p.setFont("Helvetica", 9)

        # Table rows per carwash
        for carwash in carwashes:
            if y < inch:
                p.showPage()
                y = height - inch
                p.setFont("Helvetica-Bold", 10)
                for i, header in enumerate(headers):
                    p.drawString(x_positions[i], y, header)
                y -= 0.3 * inch
                p.setFont("Helvetica", 9)

            bookings = Booking.objects.filter(tenant=tenant, carwash=carwash)
            if not bookings.exists():
                continue

            total = bookings.count()
            income = bookings.aggregate(total=Sum('amount'))['total'] or 0
            arpw = income / total if total else 0
            unique = bookings.values('phone_number').distinct().count()
            repeat = bookings.values('phone_number').annotate(c=Count('id')).filter(c__gt=1).count()
            repeat_rate = (repeat / unique * 100) if unique else 0
            top_service = (
                bookings.values('service__name')
                .annotate(count=Count('id'))
                .order_by('-count')
                .first()
            )
            top_service_name = top_service['service__name'] if top_service else "N/A"
            online = bookings.filter(booking_source='online').count()
            walkin = bookings.filter(booking_source='walk_in').count()

            row = [
                carwash.name[:12], str(total), f"{income:.1f}", f"{arpw:.1f}",
                str(unique), str(repeat), f"{repeat_rate:.1f}%",
                top_service_name[:10], str(online), str(walkin)
            ]

            for i, value in enumerate(row):
                p.drawString(x_positions[i], y, value)
            y -= 0.25 * inch

        p.showPage()
        p.save()
        buffer.seek(0)
        return FileResponse(buffer, as_attachment=True, filename='tenant_kpi_comparison.pdf')
        