import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Bool "mo:base/Bool";

actor {
    type Profile = {
        username : Text;
        bio : Text;
    };

    type GetProfileError = {
        #userNotAuthenticated;
        #profileNotFound;
    };

    type GetProfileResponse = Result.Result<Profile, GetProfileError>;

    type CreateProfileError = {
        #profileAlreadyExists;
        #userNotAuthenticated;
    };

    type CreateProfileResponse = Result.Result<Bool, CreateProfileError>;

    let profiles = HashMap.HashMap<Principal, Profile>(0, Principal.equal, Principal.hash);

    public query ({caller}) func getProfile () : async GetProfileResponse {
        if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);

        let profile = profiles.get(caller);

        switch profile {
            case (?profile) {
                #ok(profile);
            };
            case null {
                #err(#profileNotFound);
            };
        }
    };

    public shared ({caller}) func createProfile (username : Text, bio : Text) : async CreateProfileResponse {
        if (Principal.isAnonymous(caller)) return #err(#userNotAuthenticated);

        let profile = profiles.get(caller);

        if (profile != null) return #err(#profileAlreadyExists);

        let newProfile: Profile = {
            username = username;
            bio = bio;
        };
        
        profiles.put(caller, newProfile);

        #ok(true);
    };
}
