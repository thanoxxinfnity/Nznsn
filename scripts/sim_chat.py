#!/usr/bin/env python3
"""Sim.ai deployed-chat client. Usage: sim_chat.py "message" [conversation_id]"""
import sys, json, urllib.request

CHAT_ID = "1238272ue"
URL = f"https://www.sim.ai/api/chat/{CHAT_ID}"

def ask(text, conversation_id=None, timeout=180):
    body = {"input": text}
    if conversation_id:
        body["conversationId"] = conversation_id
    req = urllib.request.Request(URL, json.dumps(body).encode(), {"Content-Type": "application/json"})
    out, cid = [], conversation_id
    with urllib.request.urlopen(req, timeout=timeout) as r:
        for raw in r:
            line = raw.decode().strip()
            if not line.startswith("data:"):
                continue
            data = line[5:].strip()
            if data == '"[DONE]"':
                break
            try:
                ev = json.loads(data)
            except ValueError:
                continue
            if isinstance(ev, dict):
                if "chunk" in ev:
                    out.append(ev["chunk"])
                cid = ev.get("conversationId", cid)
    return "".join(out), cid

if __name__ == "__main__":
    text, cid = ask(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
    print(text)
    print(f"\n[conversationId={cid}]", file=sys.stderr)
