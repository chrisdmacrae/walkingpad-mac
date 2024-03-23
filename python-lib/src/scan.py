import asyncio
from ph4_walkingpad import pad
from ph4_walkingpad.pad import Scanner
from ph4_walkingpad.utils import setup_logging

log = setup_logging()
pad.logger = log

async def scan():
    scanner = Scanner()
    await scanner.scan()
    
loop = asyncio.new_event_loop()
asyncio.set_event_loop(loop)
loop.run_until_complete(scan())
loop.close()
