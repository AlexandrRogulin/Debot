pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

struct Purchase{
    uint32 id;
    string name;
    uint32 amount;
    uint64 time;
    bool isPaid;
    uint64 price;
}

struct PurchasesSummary {
    uint32 paidPurchases;
    uint32 unpaidPurchases;
    uint128 spandMoney;
}

interface IShoppingList {
    function getPurchases() external view returns(Purchase[] myPurchases);
    function pushPurchase(string purchaseName, uint32 amount) external;
    function deletePurchase(uint32 purchaseId) external;
    function buyPurchase(uint32 purchaseId, uint64 fullPrice) external;
    function getSummary() external returns(PurchasesSummary summary);
}

interface Transactable {
    function sendTransaction(address destination, uint128 value, bool bounce, uint8 flag, TvmCell payload) external;
}

abstract contract HasConstructorWithPubKey {
    constructor(uint publicKeyWhenDeploy) public {}
}