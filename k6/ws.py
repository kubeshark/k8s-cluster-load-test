import websocket
import _thread
import time
import json
import webbrowser

def on_message(ws, message):
    d = json.loads(message)
    print(d["dst"]["ip"], d["dst"]["port"])

def on_error(ws, error):
    print(error)

def on_close(ws, close_status_code, close_msg):
    print("### closed ###")

def on_open(ws):
    pass

if __name__ == "__main__":
    ws = websocket.WebSocketApp("ws://localhost:30001/ws?worker=worker&node=node&c=123457",
        on_open=on_open,
        on_message=on_message,
        on_error=on_error,
        on_close=on_close
    )

    ws.run_forever()
