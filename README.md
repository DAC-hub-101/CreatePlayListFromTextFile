# 🎵 Spotify Playlist Importer (Bash Script)

A lightweight Bash script that reads a list of songs from a text file and automatically imports them into a new Spotify playlist.

It uses the Spotify Web API to search for tracks and add them in batches.

---

## 🚀 Prerequisites for Windows Users (WSL)

This script is written in **Bash (Linux)**. To run it on Windows, you need **WSL (Windows Subsystem for Linux)**.

### How to Install WSL

If you don’t already have Linux on your Windows machine:

1. Open the **Start Menu**, search for **PowerShell**, right-click it, and select **Run as Administrator**.
2. Run the following command:
   ```powershell
   wsl --install


Restart your computer when prompted.

After reboot, Ubuntu will launch automatically to finish setup.

Create a username and password when asked.

📦 Dependencies (Required)

You must have the following tools installed:

curl – sends HTTP requests to Spotify

jq – parses JSON responses

Install on Ubuntu / Debian (WSL standard)
sudo apt update
sudo apt install curl jq -y

## 🔐 Configuration: Getting the Access Token (Workaround)

### Why is this needed?

Spotify has paused new developer app creation, so we can’t generate API keys normally.  
Instead, we temporarily extract a valid token from Spotify’s own API documentation.

---

### Step 1: Get the Token via Browser

1. Open the **Spotify Web API Console – Create Playlist** page.
2. Log in to your Spotify account if required.
3. Open **Developer Tools**:
   - Press `F12`, or
   - Right-click → **Inspect**
4. Go to the **Network** tab.
5. Generate traffic:
   - Click the green **TRY IT** button
   - Fill any required dummy data (e.g. `1` for User ID)
6. Find the request:
   - Look for a request named `playlists` or `users`
   - Click it
7. In the **Request Headers** section, locate:


Authorization: Bearer BQDqm...

8. Copy **only** the token part after `Bearer`.

---

### Step 2: Paste the Token into the Script

1. Open the script:
```bash
nano CreateSpotifyPlaylistUtil.sh


Find the variable at the top:

ACCESS_TOKEN=""


Paste your token:

ACCESS_TOKEN="PASTE_YOUR_LONG_TOKEN_HERE"


Save and exit:

Ctrl + O, Enter

Ctrl + X

⚠️ Important:
The token expires after 1 hour.
If you get a 401 Unauthorized error, repeat the steps above to grab a new token.

📝 Usage
Clone the repository
git clone https://github.com/DAC-hub-101/CreatePlayListFromTextFile.git
cd CreatePlayListFromTextFile

Make the script executable
chmod +x CreateSpotifyPlaylistUtil.sh

Prepare your song list

Edit playlist.txt and add one song per line in the format:

Artist Name Song Name


Example:

The Prodigy Hotride
Metallica Enter Sandman
Eminem Lose Yourself

Run the script
./CreateSpotifyPlaylistUtil.sh


This now:
- renders correctly
- respects Markdown structure
- doesn’t randomly collapse into paragraphs
- won’t make future-you angry

