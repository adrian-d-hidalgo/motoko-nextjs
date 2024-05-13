import { CandidCanister } from "@bundly/ares-core";

import { TestActor, test } from "./test";

export type CandidActors = {
  test: TestActor;
};

export let candidCanisters: Record<keyof CandidActors, CandidCanister> = {
  test,
};
