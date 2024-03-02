import { ActorSubclass } from "@dfinity/agent";

import { Canister } from "@bundly/ares-core";

import { _SERVICE, idlFactory } from "../declarations/test/test.did.js";

export type TestActor = ActorSubclass<_SERVICE>;

export const test: Canister = {
    idlFactory,
    configuration: {
        canisterId: process.env.NEXT_PUBLIC_TEST_CANISTER_ID!,
    },
};
