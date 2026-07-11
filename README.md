# KhataBook WhatsApp — How to get the APK (Simple Steps)

Follow these steps exactly, in order. No coding knowledge needed. Total time:
about 10-15 minutes, and it's free.

---

## Step 1: Create a free GitHub account

1. Go to https://github.com/signup
2. Sign up with your email (it's free).

---

## Step 2: Create a new empty repository

1. After logging in, click the **"+"** icon (top right) → **"New repository"**.
2. Repository name: type `khatabook-whatsapp`
3. Keep it **Public**.
4. Do NOT check any boxes (no README, no .gitignore).
5. Click **"Create repository"**.

---

## Step 3: Upload the project files

1. On the new (empty) repository page, click **"uploading an existing file"**
   (a blue link in the middle of the page).
2. Now, on your computer, **unzip** the `khatabook_whatsapp.zip` file I gave
   you. You'll see a folder called `khatabook_whatsapp` with everything
   inside it (lib, android, pubspec.yaml, etc.)
3. Open that unzipped `khatabook_whatsapp` folder, select **everything
   inside it** (all files and folders — select all, Ctrl+A / Cmd+A), and
   **drag them** into the GitHub upload box in your browser.
   - Important: drag the *contents* of the folder, not the folder itself.
4. Wait for the upload to finish (progress bar at the bottom).
5. Scroll down, click the green **"Commit changes"** button.

---

## Step 4: Let GitHub build the APK automatically

This project already includes a build robot (`.github/workflows/build-apk.yml`)
that you uploaded in Step 3. The moment your files finish uploading, GitHub
starts building the app automatically — you don't need to do anything.

1. Click the **"Actions"** tab at the top of your repository page.
2. You'll see a build running (yellow dot = in progress, may take 5-8 minutes).
3. Wait until the yellow dot turns into a **green checkmark**.
   - If it turns into a red X, click into it and see the error message —
     you're welcome to paste it back to me and I'll help you fix it.

---

## Step 5: Download your APK

1. Once you see the green checkmark, click on that build run.
2. Scroll down to the **"Artifacts"** section at the bottom of the page.
3. Click **"khatabook-whatsapp-apk"** to download it — this is a `.zip` file
   containing your `.apk`.
4. Unzip it on your computer. Inside you'll find `app-release.apk`.

---

## Step 6: Install it on your Android phone

1. Send `app-release.apk` to your phone (WhatsApp yourself, email, USB
   cable, or Google Drive — any way works).
2. On your phone, tap the file to open it.
3. Android will warn "Install blocked" or "Unknown source" the first time —
   tap **Settings** → allow installs from that app (Chrome/Files/WhatsApp) →
   go back and tap **Install**.
4. Done! Open "KhataBook WhatsApp" from your app drawer.

---

## That's it!

Every time you (or I) update the code and re-upload it to the same GitHub
repository, a new APK will build automatically — just repeat Steps 4-5 to
grab the newest version.

### If something goes wrong
The most likely failure point is Step 4 (the Actions build going red).
Click into the failed run, copy the red error text near the bottom, and
send it to me — I'll tell you exactly what to fix.
