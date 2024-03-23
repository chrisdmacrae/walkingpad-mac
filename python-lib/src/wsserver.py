# To install deps:
# python3 -m pip install --no-cache-dir -r requirements.txt

import sys
import asyncio
import websockets
import yaml
from datetime import date

from ph4_walkingpad import pad
from ph4_walkingpad.pad import WalkingPad, Controller
from ph4_walkingpad.utils import setup_logging

import logging
import json
import threading

import argparse
parser = argparse.ArgumentParser(description='Example script to demonstrate argument parsing.')
parser.add_argument('--mac', '-m', type=str, required=True, help='Mac Address of Treadmill')
args = parser.parse_args()

import logging
logger = logging.getLogger('websockets')
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())

minimal_cmd_space = 0.69

log = setup_logging()
pad.logger = log
ctler = Controller()

current_record = {}

def get_or_create_eventloop():
    try:
        return asyncio.get_event_loop()
    except RuntimeError as ex:
        if "There is no current event loop in thread" in str(ex):
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            return asyncio.get_event_loop()

async def connect(params):
    print("Connecting")
    address = args.mac
    print("Connecting to {0}".format(address))
    await ctler.run(address)
    await asyncio.sleep(minimal_cmd_space)
    

async def disconnect(params):
    await ctler.disconnect()
    await asyncio.sleep(minimal_cmd_space)

async def run(params):
    await ctler.switch_mode(WalkingPad.MODE_STANDBY) # Ensure we start from a known state, since start_belt is actually toggle_belt
    await asyncio.sleep(minimal_cmd_space)
    await ctler.switch_mode(WalkingPad.MODE_MANUAL)
    await asyncio.sleep(minimal_cmd_space)
    await ctler.start_belt()
    await asyncio.sleep(minimal_cmd_space)
    await ctler.ask_hist(0)
    await asyncio.sleep(minimal_cmd_space)

async def stop(params):
    await ctler.switch_mode(WalkingPad.MODE_STANDBY)
    await asyncio.sleep(minimal_cmd_space)
    await ctler.ask_hist(0)
    await asyncio.sleep(minimal_cmd_space)

async def set_speed(params):
    await ctler.change_speed(params['speed'])


async def get_stats(params):
    await ctler.ask_stats()
    await asyncio.sleep(minimal_cmd_space)
    stats = ctler.last_status

    return {
        "dist": stats.dist,
        "time": stats.time,
        "speed": stats.speed,
        "state": stats.belt_state,
        "steps": stats.steps,
    }


async def pong(params):
  return {
      "method": "pong"
  }


methods = {
    "connect": connect,
    "disconnect": disconnect,
    "run": run,
    "stop": stop,
    "set_speed": set_speed,
    # "set_to_standby": set_to_standby,
    "get_stats": get_stats,
    "ping": pong
}

async def handle_method(ws, id, method, params = {}):
  result = await methods[method](params)

  if result is not None:
    await ws.send(json.dumps({
      "id": id,
      "result": result
    }))
  else:
    await ws.send(json.dumps({
      "id": id,
      "result": "ok"
    }))

async def consumer(data, ws):
    if data == "pong":
        print("Pong received")
        return

    json_data = json.loads(data)
    method = json_data['method']

    if method in methods:
        asyncio.ensure_future(handle_method(ws, json_data.get('id'), method, json_data.get(
            'params'
        )))
    else:
        print("Unknown method: " + data)

async def consumer_handler(websocket):
    async for message in websocket:
        print("Received message: " + message)
        await consumer(message, websocket)


async def main():
    async with websockets.serve(consumer_handler, "localhost", 8765, ping_timeout=None, ping_interval=None):
        print("Server is ready")
        await asyncio.Future()  # run forever

if __name__ == "__main__":
    asyncio.run(main())
