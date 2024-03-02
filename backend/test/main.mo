import Principal "mo:base/Principal";

actor {
    public query (message) func whoAmI () : async Principal {
        return message.caller;
    }
}
