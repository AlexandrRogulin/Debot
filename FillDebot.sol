pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "base/Debot.sol";
import "base/Terminal.sol";
import "base/Menu.sol";
import "base/AddressInput.sol";
import "base/ConfirmInput.sol";
import "base/Upgradable.sol";
import "base/Sdk.sol";

// Our contracts and debots
import "InterfacesAndStructs.sol";
import "AbsDebot.sol";

// This bot can add, remove purchases to the shopping list and show information about the existing list 
contract FillDebot is Debot, AbsDebot {
    string m_purchaseName;

    function start() virtual public override(Debot, AbsDebot) {}

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() virtual public functionID(0xDEB) override(Debot, AbsDebot) view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {}

    function getRequiredInterfaces() virtual public view override returns (uint256[] interfaces) {}

    function _menu() virtual override internal{}

    //=====================================================================================
    // This method adds purchases to the shopping list
    function addPurchase(uint32 index) public{
        Terminal.input(tvm.functionId(setPurchaseName), "Enter purchase name: ", false);
    }

    function setPurchaseName(string value) public{
        m_purchaseName = value;

        Terminal.input(tvm.functionId(setPurchaseAmount), "Enter purchase amount: ", false);
    }

    function setPurchaseAmount(string value) public {
        (uint purchaseAmount, bool status) = stoi(value);

        if(status) {
            callAddPurchase(uint32(purchaseAmount));
        } else {
            Terminal.print(0, "Ooops! Sorry, amount must be integer!");
            addPurchase(1);
        }

    }

    function callAddPurchase(uint32 purchaseAmount) public view {
        optional(uint256) pubkey = 0;

        IShoppingList(m_address).pushPurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
        }(m_purchaseName, purchaseAmount);
    }

    //=====================================================================================
    // These methods show the existing shopping list
    function showMyShopList(uint8 index) public view {
        optional(uint) none;

        IShoppingList(m_address).getPurchases{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(getMyShopList),
            onErrorId: 0
        }();
    }

    function getMyShopList(Purchase[] myPurchases) public {
        if(!myPurchases.empty()) {
            Terminal.print(0, "Your shopping list:");
            for((Purchase purchase) : myPurchases) {
                string paid;
                if (purchase.isPaid) {
                    paid = ' ✓ ';
                } else {
                    paid = '___';
                }
                Terminal.print(0, format("{} {}  \"{}\" how many: {}", purchase.id, paid, purchase.name, purchase.amount));
            }
        } else {
            Terminal.print(0, "Your shopping list is empty");
        }
        _menu();
    }

    //=====================================================================================
    // These methods remove some purchase
    function deleteSomePurchase() public {
        if (m_summary.unpaidPurchases + m_summary.paidPurchases > 0) {
            Terminal.input(tvm.functionId(deleteSomePurchase_), "Enter purchase id with you want to delete: ", false);
        } else {
            Terminal.print(0, "Sorry, you deleted all the purchases");
            _menu();
        }
    }

    function deleteSomePurchase_(string value) public{
        (uint id, bool status) = stoi(value);

        if(status) {
            optional(uint256) pubkey = 0;
            IShoppingList(m_address).deletePurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0, 
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(uint32(id));
        } else {
            Terminal.print(0, "Ooops! Sorry, id must be integer!");
            deleteSomePurchase();
        }
    }
}