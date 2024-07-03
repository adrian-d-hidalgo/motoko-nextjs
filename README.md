# Fullstack dApp (Motoko + NextJS + Internet Identity)

This template is designed to easily build applications deployed on ICP using Motoko + Next.js + Internet Identity

## Table of Contents

- [Getting Started](#getting-started)
  - [In the Cloud](#in-the-cloud)
  - [Manual Setup](#manual-setup)

## Getting Started

### In the cloud

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/adrian-d-hidalgo/motoko-nextjs/?quickstart=1)

Create a .env file:

```bash
cp frontend/.env-codespaces-example frontend/.env
```

Get environment values:

```bash
# Create all canisters
dfx canister create --all

# Get backend canister id
dfx canister id test

# Get internet-identity canister id
dfx canister id internet-identity

# Get your Codespace name
echo $CODESPACE_NAME
```

Replace values in the `frontend/.env` file:

```bash
# Replace YOUR_CODESPACE_NAME with your Codespace name
NEXT_PUBLIC_IC_HOST_URL=https://YOUR_CODESPACE_NAME-4943.app.github.dev/
# Replace YOUR_TEST_CANISTER_ID with your test canister id
NEXT_PUBLIC_TEST_CANISTER_ID=YOUR_TEST_CANISTER_ID
# Replace YOUR_INTERNET_IDENTITY_CANISTER_ID with your internet-identity canister id
NEXT_PUBLIC_INTERNET_IDENTITY_URL=https://YOUR_CODESPACE_NAME-4943.app.github.dev/?canisterId=YOUR_INTERNET_COMPUTER_CANISTER_ID
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
    frontend:
      - http://127.0.0.1:4943/?canisterId=bkyz2-fmaaa-aaaaa-qaaaq-cai
      - http://bkyz2-fmaaa-aaaaa-qaaaq-cai.localhost:4943/
    internet-identity:
      - http://127.0.0.1:4943/?canisterId=bd3sg-teaaa-aaaaa-qaaba-cai
      - http://bd3sg-teaaa-aaaaa-qaaba-cai.localhost:4943/
  Backend canister via Candid interface:
    internet-identity: http://127.0.0.1:4943/?canisterId=br5f7-7uaaa-aaaaa-qaaca-cai&id=bd3sg-teaaa-aaaaa-qaaba-cai
    test: http://127.0.0.1:4943/?canisterId=br5f7-7uaaa-aaaaa-qaaca-cai&id=be2us-64aaa-aaaaa-qaabq-cai
```

To interact with the frontend the url can be obtained as follows:

```bash
echo https://$CODESPACE_NAME-4943.app.github.dev/?canisterId=$(dfx canister id frontend)
```

### Manual Setup

Ensure the following are installed on your system:

- [Node.js](https://nodejs.org/en/) `>= 21`
- [DFX](https://internetcomputer.org/docs/current/developer-docs/build/install-upgrade-remove) `>= 0.20.1`

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

Replace values in the .env file:

```bash
# Replace port if needed
NEXT_PUBLIC_IC_HOST_URL=http://localhost:4943
# Replace YOUR_TEST_CANISTER_ID with your test canister id
NEXT_PUBLIC_TEST_CANISTER_ID=YOUR_TEST_CANISTER_ID
# Replace YOUR_INTERNET_IDENTITY_CANISTER_ID with your internet-identity canister id
NEXT_PUBLIC_INTERNET_IDENTITY_URL=http://YOUR_INTERNET_IDENTITY_CANISTER_ID.localhost:4943
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
    frontend:
      - http://127.0.0.1:4943/?canisterId=bkyz2-fmaaa-aaaaa-qaaaq-cai
      - http://bkyz2-fmaaa-aaaaa-qaaaq-cai.localhost:4943/
    internet-identity:
      - http://127.0.0.1:4943/?canisterId=bd3sg-teaaa-aaaaa-qaaba-cai
      - http://bd3sg-teaaa-aaaaa-qaaba-cai.localhost:4943/
  Backend canister via Candid interface:
    internet-identity: http://127.0.0.1:4943/?canisterId=br5f7-7uaaa-aaaaa-qaaca-cai&id=bd3sg-teaaa-aaaaa-qaaba-cai
    test: http://127.0.0.1:4943/?canisterId=br5f7-7uaaa-aaaaa-qaaca-cai&id=be2us-64aaa-aaaaa-qaabq-cai
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
