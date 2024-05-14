import { Identity } from "@dfinity/agent";
import React, { ChangeEvent, FormEvent, useEffect, useState } from "react";

import { LogoutButton, useAuth, useCandidActor, useIdentities } from "@bundly/ares-react";

import { CandidActors } from "@app/canisters";
import Header from "@app/components/header";

type Profile = {
  username: string;
  bio: string;
};

export default function IcConnectPage() {
  const { isAuthenticated, currentIdentity, changeCurrentIdentity } = useAuth();
  const identities = useIdentities();
  const [profile, setProfile] = useState<Profile | undefined>();
  const [loading, setLoading] = useState(false); // State for loader
  const test = useCandidActor<CandidActors>("test", currentIdentity, {
    canisterId: process.env.NEXT_PUBLIC_TEST_CANISTER_ID,
  }) as CandidActors["test"];

  useEffect(() => {
    getProfile();
  }, [currentIdentity]);

  function formatPrincipal(principal: string): string {
    const parts = principal.split("-");
    const firstPart = parts.slice(0, 2).join("-");
    const lastPart = parts.slice(-2).join("-");
    return `${firstPart}-...-${lastPart}`;
  }

  function disableIdentityButton(identityButton: Identity): boolean {
    return currentIdentity.getPrincipal().toString() === identityButton.getPrincipal().toString();
  }

  async function getProfile() {
    try {
      const response = await test.getProfile();

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) console.log("User not authenticated");
        else console.log("Error fetching profile");
      }

      const profile = "ok" in response ? response.ok : undefined;
      setProfile(profile);
    } catch (error) {
      console.error({ error });
    }
  }

  async function registerProfile(username: string, bio: string) {
    try {
      setLoading(true); // Show loader
      const response = await test.createProfile(username, bio);

      if ("err" in response) {
        if ("userNotAuthenticated" in response.err) alert("User not authenticated");
        if ("profileAlreadyExists" in response.err) alert("Profile already exists");

        throw new Error("Error creating profile");
      }

      setProfile({ username, bio });
    } catch (error) {
      console.error({ error });
    } finally {
      setLoading(false); // Hide loader
    }
  }

  return (
    <>
      <Header />
      <main className="p-6">
        <div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 py-8">
            <div className="bg-white rounded-lg shadow-md p-6">
              <h2 className="text-xl font-bold mb-2">User Info</h2>
              <p className="mt-4 text-sm text-gray-500">
                <strong>Status:</strong> {isAuthenticated ? "Authenticated" : "Not Authenticated"}
              </p>
              <p className="text-gray-700">
                <strong>Current Identity:</strong> {currentIdentity.getPrincipal().toString()}
              </p>
              <h2 className="text-xl font-bold mb-2">Profile</h2>
              {profile ? (
                <>
                  <p>
                    <strong>Username: </strong> {profile.username}
                  </p>
                  <p>
                    <strong>Bio: </strong> {profile.bio}
                  </p>
                </>
              ) : (
                <CreateProfileForm onSubmit={registerProfile} loading={loading} />
              )}
            </div>

            <div className="bg-white rounded-lg shadow-md p-6">
              <h2 className="text-xl font-bold mb-2">Identities</h2>
              <ul className="divide-y divide-gray-200">
                {identities.map((identity, index) => (
                  <li key={index} className="flex items-center justify-between py-4">
                    <span className="text-gray-900">
                      {identity.provider} : {formatPrincipal(identity.identity.getPrincipal().toString())}
                    </span>
                    <div className="flex gap-2">
                      <button
                        className={`px-3 py-1 text-sm rounded-md ${
                          disableIdentityButton(identity.identity)
                            ? "bg-gray-300 text-gray-500 cursor-not-allowed"
                            : "bg-blue-500 text-white"
                        }`}
                        disabled={disableIdentityButton(identity.identity)}
                        onClick={() => changeCurrentIdentity(identity.identity)}>
                        Select
                      </button>
                      <LogoutButton identity={identity.identity} />
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </main>
    </>
  );
}

type ProfileFormProps = {
  onSubmit: (username: string, bio: string) => Promise<void>;
  loading: boolean; // Loader state
};

function CreateProfileForm({ onSubmit, loading }: ProfileFormProps) {
  const [username, setUsername] = useState("");
  const [bio, setBio] = useState("");

  const handleUsernameChange = (event: ChangeEvent<HTMLInputElement>) => {
    setUsername(event.target.value);
  };

  const handleBioChange = (event: ChangeEvent<HTMLTextAreaElement>) => {
    setBio(event.target.value);
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    await onSubmit(username, bio);
    resetForm();
  };

  const resetForm = () => {
    setUsername("");
    setBio("");
  };

  return (
    <form onSubmit={handleSubmit}>
      <div className="mb-4">
        <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="username">
          Username
        </label>
        <input
          className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
          id="username"
          type="text"
          placeholder="Username"
          value={username}
          onChange={handleUsernameChange}
        />
      </div>
      <div className="mb-6">
        <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="bio">
          Bio
        </label>
        <textarea
          className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
          id="bio"
          placeholder="Bio"
          value={bio}
          onChange={handleBioChange}
        />
      </div>
      <div className="flex items-center justify-between">
        <button
          className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
          type="submit"
          disabled={loading} // Disable button while loading
        >
          {loading ? "Creating Profile..." : "Create Profile"}
        </button>
      </div>
    </form>
  );
}
