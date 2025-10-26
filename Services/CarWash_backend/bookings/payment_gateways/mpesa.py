import requests
import datetime
import base64
import json
import re
from requests.auth import HTTPBasicAuth
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from bookings.models import Booking, CarWash, Service

def sanitize_phone_number(phone):
    phone = str(phone).strip().replace(" ", "")
    phone = re.sub(r'\D', '', phone)

    if phone.startswith("0") and len(phone) == 10:
        return "254" + phone[1:]
    elif phone.startswith("7") and len(phone) == 9:
        return "254" + phone
    elif phone.startswith("254") and len(phone) == 12:
        return phone
    else:
        raise ValueError("❌ Invalid phone number format: " + phone)


def get_access_token(consumer_key, consumer_secret, is_sandbox=True):
    base_url = 'https://sandbox.safaricom.co.ke' if is_sandbox else 'https://api.safaricom.co.ke'
    url = f"{base_url}/oauth/v1/generate?grant_type=client_credentials"

    try:
        response = requests.get(url, auth=HTTPBasicAuth(consumer_key, consumer_secret))
        response.raise_for_status()
        data = response.json()
        access_token = data.get("access_token")

        if not access_token:
            raise Exception("No access token in response: " + str(data))
        return access_token
    except requests.exceptions.HTTPError as http_err:
        raise Exception(f"❌ HTTP error during token fetch: {response.status_code} {response.text}")
    except Exception as e:
        raise Exception(f"❌ Unexpected error fetching token: {str(e)}")

def lipa_na_mpesa(amount, phone_number, metadata):
    import datetime
    from Tenant.models import CarWash, Service

    carwash = CarWash.objects.get(id=metadata["carwash_id"])
    services = Service.objects.filter(id__in=metadata.get("service_ids", []))

    # Combine service names into a single string
    service_names = ", ".join([s.name for s in services])
    
    reference = f"Booking-{metadata.get('user_id')}-{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}"
    description = f"{service_names} at {carwash.name}"
    is_sandbox = carwash.mpesa_env == "sandbox"
    base_url = "https://sandbox.safaricom.co.ke" if is_sandbox else "https://api.safaricom.co.ke"

    try:
        access_token = get_access_token(
            carwash.mpesa_consumer_key,
            carwash.mpesa_consumer_secret,
            is_sandbox
        )
    except Exception as token_error:
        return {"error": str(token_error)}

    try:
        timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
        password = base64.b64encode(
            (carwash.mpesa_shortcode + carwash.mpesa_passkey + timestamp).encode()
        ).decode()
        phone = sanitize_phone_number(phone_number)

        payload = {
            "BusinessShortCode": carwash.mpesa_shortcode,
            "Password": password,
            "Timestamp": timestamp,
            "TransactionType": "CustomerPayBillOnline",
            "Amount": int(amount),
            "PartyA": phone,
            "PartyB": carwash.mpesa_shortcode,
            "PhoneNumber": phone,
            "CallBackURL": "https://undecayable-tiffaney-phrenogastric.ngrok-free.dev/api/bookings/mpesa/callback/",

            "AccountReference": reference,
            "TransactionDesc": description,
        }

        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }

        response = requests.post(
            f"{base_url}/mpesa/stkpush/v1/processrequest",
            headers=headers,
            json=payload,
        )
        response.raise_for_status()
        return response.json()

    except requests.exceptions.HTTPError as err:
        return {"error": f"STK push HTTP error: {response.status_code} {response.text}"}
    except Exception as e:
        return {"error": f"STK push error: {str(e)}"}
