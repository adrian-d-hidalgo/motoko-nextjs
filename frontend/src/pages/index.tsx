import { CandidActors } from "@app/canisters";
import { AuthButton, useCandidActor } from "@bundly/ares-react";

export default function IcConnectPage() {
    const backend = useCandidActor<CandidActors>("test") as CandidActors["test"];

    async function whoAmI() {
        try {
            const response = await backend.whoAmI();

            console.log({
                pricipal: response.toString(),
                isAnonymous: response.isAnonymous(),
            });
        } catch (error) {
            console.error({ error });
        }
    }

    return (
        <div>
            <h1>IC Connect</h1>
            <AuthButton />
            <div>
                <button onClick={() => whoAmI()}>Who Am I</button>
            </div>
        </div>
    );
}
