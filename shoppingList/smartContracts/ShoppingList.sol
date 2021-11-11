pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../interface/interfaceAndStructs.sol";


contract ShoppingList is IShoppingList {

    uint32 m_lastId;
    uint256 m_ownerPubkey;

    mapping(uint32 => Purchase) m_purchases;

    constructor(uint256 pubkey) public {
        require(pubkey != 0, 120);
        tvm.accept();
        m_ownerPubkey = pubkey;
    }

    modifier onlyOwner() {
        require(msg.pubkey() == m_ownerPubkey, 101);
        _;
    }
    
    modifier checkPurchaseExist(uint32 purchaseId) {
        require(m_purchases.exists(purchaseId), 201, "Purchase with this id doesn't exist");
        _;
    }
    
    function addPurchase(string title, uint32 quantity) public override onlyOwner {
        tvm.accept();
        m_lastId++;
        m_purchases[m_lastId] = Purchase(m_lastId, title, quantity, 0, false, now);
    }

    function deletePurchase(uint32 id) public override onlyOwner checkPurchaseExist(id) {
        tvm.accept();
        delete m_purchases[id];
    }

    function confirmPurchase(uint32 id, uint32 _price) external override onlyOwner checkPurchaseExist(id) {
        require(!m_purchases[id].isConfirmed, 202, "This purchase already confirmed");
        tvm.accept();
        m_purchases[id].price = _price;
        m_purchases[id].isConfirmed = true;
    }

    function getPurchases() external view override returns (Purchase[] purchases) {
        string itemName;
        uint64 dataCreated;
        bool isDone;

        for((uint32 id, Purchase purchase) : m_purchases) {
            purchases.push(
                Purchase(
                    id,
                    purchase.title,
                    purchase.quantity,
                    purchase.dataCreated,
                    purchase.isConfirmed,
                    purchase.price
                )
            );
       }
    }

    function getSummary() external view override returns (PurchasesSummary) {
        uint32 countPaid;
        uint32 countUnpaid;
        uint32 totalPaid;

        for((, Purchase purchase) : m_purchases) {
            if (purchase.isConfirmed) {
                countPaid ++;
                totalPaid += purchase.price;
            } else {
                countUnpaid ++;
            }
        }
        return PurchasesSummary(countPaid, countUnpaid, totalPaid);
    }
}