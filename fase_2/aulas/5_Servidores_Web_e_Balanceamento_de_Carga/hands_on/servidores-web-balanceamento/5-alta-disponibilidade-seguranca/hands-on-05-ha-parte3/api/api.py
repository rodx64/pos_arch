from flask import Flask
import time

app = Flask(__name__)

@app.route("/api/")
def api():
    time.sleep(1)  # simula processamento
    return "API chamada com sucesso!\n", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
