import nats
import requests # type: ignore
import json
import asyncio

async def process_message(msg):
    data = json.loads(msg.data.decode())
    client_id = data["client_id"]

    # Call Panorama API
    headers = {
        "Content-Type": "application/json",
        "panorama_user": "IIDISystem",
        "accept-language": "en-CA"
    }
    payload = {"client": {"id": client_id}}
    try:
        response = requests.post(
            "https://panenv5web.panorama.gov.bc.ca:8080/SDSM/API/Immunization/Recorded/Query",
            headers=headers,
            json=payload,
            cert=("/certs/cert.pem", "/certs/key.pem")
        )
        result = response.json()
    except Exception as e:
        result = {"error": str(e)}

    # Publish response to NATS
    await nc.publish("panorama.api.response", json.dumps(result).encode())

async def main():
    global nc
    nc = await nats.connect("nats://nats-headless.bc.svc.cluster.local:4222")
    await nc.subscribe("panorama.api.request", cb=process_message)

if __name__ == "__main__":
    asyncio.run(main())
