pragma ton-solidity >= 0.35.0;

struct Purchase {
    uint32 id;
    string title;
    uint32 quantity;
    uint64 dataCreated;
    bool isConfirmed;
    uint32 price;
}

struct PurchasesSummary {
    uint32 countPaid;
    uint32 countUnpaid;
    uint32 totalPaid;
}

interface IShoppingList {
    function addPurchase(string title, uint32 quantity) external;
    function deletePurchase(uint32 id) external;
    function confirmPurchase(uint32 id, uint32 price) external;
    function getPurchases() external view returns (Purchase[] purchases);
    function getSummary() external view returns (PurchasesSummary);
}

interface Transactable {
   function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload) external;
}

abstract contract HasConstructorWithPubKey {
    constructor(uint256 pubkey) public {}
}