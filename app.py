from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello World!", 200

if __name__ == '__main__':
    port = int(os.getenv("APP_PORT", 5000))
    app.run(host='0.0.0.0', port=port, debug=False, use_reloader=False)