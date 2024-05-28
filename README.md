# Fullstack dApp (Motoko + NextJS + Internet Identity)

This template is designed to easily build applications deployed on ICP using Motoko + Next.js + Internet Identity

## Run in the cloud

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/adrian-d-hidalgo/motoko-nextjs/?quickstart=1)

## Run Locally

Clone the project

```bash
  git clone https://github.com/adrian-d-hidalgo/motoko-nextjs.git
```

Go to the project directory

```bash
  cd motoko-nextjs
```

Install dependencies

```bash
npm install
```

Create a .env file:

```bash
# Create .env file
cp frontend/.env-example frontend/.env
```

Start a ICP local replica:

```bash
dfx start --background --clean
```

Get your canister ids:

```bash
# Create canisters
dfx canister create --all

# Get backend canister id
dfx canister id test

# Get internet-identity canister id
dfx canister id internet-identity
```

Your .env file should look something like this:

```bash
# Replace port if needed
NEXT_PUBLIC_IC_HOST_URL=http://localhost:4943
# Replace YOUR_TEST_CANISTER_ID with your test canister id
NEXT_PUBLIC_TEST_CANISTER_ID=http://YOUR_TEST_CANISTER_ID.localshot:4943
# Replace YOUR_INTERNET_IDENTITY_CANISTER_ID with your internet-identity canister id
NEXT_PUBLIC_INTERNET_IDENTITY_URL=http://YOUR_INTERNET_IDENTITY_CANISTER_ID.localshot:4943
```

Generate did files:

```bash
dfx generate test
```

Deploy your canisters:

```bash
dfx deploy
```

You will receive a result similar to the following (ids could be different four you):

```bash
URLs:
  Frontend canister via browser
    frontend: http://127.0.0.1:4943/?canisterId=be2us-64aaa-aaaaa-qaabq-cai
  Backend canister via Candid interface:
    backend: http://127.0.0.1:4943/?canisterId=bd3sg-teaaa-aaaaa-qaaba-cai&id=bkyz2-fmaaa-aaaaa-qaaaq-cai
```

Open your web browser and enter the Frontend URL to view the web application in action.

## Test frontend without deploy to ICP Replica

Comment the next line into `frontend/next.config.mjs` file:

```javascript
// output: "export",
```

Then, navitate to `frontend` folder:

`cd frontend`

Run the following script:

`npm run dev`
