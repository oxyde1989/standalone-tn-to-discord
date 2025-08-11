#!/usr/bin/env python3
import sys, requests, argparse, urllib.request, socket, re

__version__ = "0.01"

def append_log(content, v_debug_enabled):
    if v_debug_enabled:        
        print(content)
        
def validate_webhook_domain(v_webhook):
    pattern = r"^https://discord\.com/api/webhooks/\d+/[A-Za-z0-9_\-]+$"
    return re.match(pattern, v_webhook) is not None        

def check_for_update(local_version):  
    github_raw_url = "https://raw.githubusercontent.com/oxyde1989/standalone-tn-to-discord/refs/heads/main/tn-to-discord.py"
    try:
        with urllib.request.urlopen(github_raw_url, timeout=5) as response:
            content = response.read().decode("utf-8")
            match = re.search(r'__version__\s*=\s*[\'"](\d+\.\d+)[\'"]', content)
            if match:
                remote_version = match.group(1)
                if remote_version > local_version:
                    return True
    except Exception as e:
        pass
    return False 

def send_discord_message(v_webhook, v_message, v_sender=None): #messages are raised anyway!
    payload = {"content": v_message}
    if v_sender:
        payload["username"] = v_sender
    try:
        r = requests.post(v_webhook, json=payload, timeout=20)
        r.raise_for_status()
        print("Message Sent. Exiting...")
    except requests.exceptions.RequestException as e:
        print(f"ERROR: {e}") 
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="standalone wrapper to send messages from Truenas to Discord via API")
    parser.add_argument("-w", "--webhook", required=True, help="Discord Webhook endpoint")
    parser.add_argument("-m", "--message", required=True, help="Message. Only direct plain-text/markdown supported")    
    parser.add_argument("-s", "--sender", help="OPTIONAL sender name")
    parser.add_argument("-d", "--debug_enabled", help="OPTIONAL verbose version. ", action='store_true')    
    
    args = parser.parse_args() 
    webhook = args.webhook
    message = args.message
    sender = args.sender
    debug_enabled = args.debug_enabled
    
    append_log("Start process", debug_enabled)
    if check_for_update(__version__):
        print(">> NEW VERSION AVAILABLE ON GITHUB. Consider to upgrade! >>")  
        
    append_log("Check message len", debug_enabled)    
    if len(message) > 2000: 
        print("ERROR: message too long") 
        sys.exit(1)   
        
    append_log("Check webhook domain", debug_enabled)      
    if not validate_webhook_domain(webhook):
        print("ERROR: Invalid Discord webhook URL?")
        sys.exit(1)      
    
    append_log("Check sender", debug_enabled)
    if not sender:
        try:
            append_log("Sender empty, applying hostname", debug_enabled)
            sender = socket.getfqdn()
            if not sender:
                sender = socket.gethostname()
                if not sender:  
                    append_log("Unable to retrieve sender, a fallback has been applied", debug_enabled)
                    sender = "Truenas BOT"
        except Exception:
            append_log("Unable to retrieve sender, a fallback has been applied", debug_enabled)
            sender = "Truenas BOT"
    else:
        append_log("Sender has been applied from args", debug_enabled)    
    append_log("Trying sending message", debug_enabled)        
    send_discord_message(webhook, message, sender)
    sys.exit(0)