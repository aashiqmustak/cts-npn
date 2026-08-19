# Alternea Healthcare 

This project integrates a **Flutter Web Frontend** application with a **Pipecat WebRTC Voice Bot Backend** (orchestrating Speech-to-Text via Sarvam, LLM via Groq, and Text-to-Speech via Sarvam).

---

## 🛠️ Method 1: Local Setup (Running Directly on Host Machine)

Running the services locally is the fastest development workflow and avoids the resource overhead of compiling PyTorch inside Docker.

### 1. Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (stable channel).
* [Python 3.12 or 3.13](https://dvip.dev/installing-python) installed.
* [uv](https://github.com/astral-sh/uv) installed (Python package manager).

### 2. Run the Backend (Pipecat Voice Bot)
1. Navigate to the root directory and activate your virtual environment:
   ```powershell
   .venv\Scripts\activate.ps1
   ```
2. Install Python dependencies:
   ```powershell
   uv sync
   ```
3. Set up your API keys in the `.env` file located at:
   `server/src/alternea_voice/features/rtc/.env`
   ```env
   SARVAM_API_KEY=your-sarvam-api-key
   GROQ_API_KEY=your-groq-api-key
   ```
4. Start the backend WebRTC runner:
   ```powershell
   python main.py -t webrtc --host localhost --port 8000
   ```

### 3. Run the Frontend (Flutter Client)
1. Open a new terminal and navigate to the `client` folder:
   ```powershell
   cd client
   ```
2. Install Dart dependencies:
   ```powershell
   flutter pub get
   ```
3. Run the Flutter Web application in Chrome:
   ```powershell
   flutter run -d chrome
   ```

---

## 🐳 Method 2: Docker Setup

Using Docker allows you to run the frontend client without needing the Flutter SDK installed on your computer.

### Prerequisites
* [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running.

---

### Option A: Hybrid Mode (Recommended for Speed)
Run the backend Python service locally (so you don't compile PyTorch inside Docker) and run the frontend in a Docker container (so you don't need the local Flutter SDK).

1. Start your local backend in your Python terminal:
   ```powershell
   python main.py -t webrtc --host localhost --port 8000
   ```
2. Build and start only the frontend container in another terminal:
   ```powershell
   docker compose up --build --no-deps frontend
   ```
3. Open [http://localhost:8080](http://localhost:8080) in your browser.

---

### Option B: Full Docker Mode (Build everything in containers)
This builds and starts both the backend and frontend services inside Docker. 

*Note: The first build will take 10-15 minutes because it compiles PyTorch, CUDA, and ONNX Runtimes inside the container.*

1. Make sure your local python backend process is **stopped** (to avoid port conflicts on port 8000).
2. Start both containers:
   ```powershell
   docker compose up --build
   ```
3. Open [http://localhost:8080](http://localhost:8080) in your browser to view the client app, which will connect to the backend container served at `localhost:8000`.

---

## 🎤 How to Test the Voice Bot
1. Open the app in your browser ([http://localhost:8080](http://localhost:8080)).
2. Log in using any role (e.g. Doctor, Patient).
3. Navigate to the **Voice Agent** screen.
4. Click the **Microphone** button to connect.
5. Grant microphone permission in your browser if prompted.
6. Speak your commands aloud and listen to the bot speak back!