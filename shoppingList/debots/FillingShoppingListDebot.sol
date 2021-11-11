pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../../base/Menu.sol";
import "InitializingShopListDebot.sol";
import "../interface/InterfaceAndStructs.sol";
import "InteractionShoppingListDebot.sol";

contract FillingShoppingListDebot is InteractionShoppingListDebot {

    string private m_productTitle;

    function listActionsMenu() internal override {
        string sep = '----------------------------------------';
        string intro = menuIntro();
        Menu.select(
            intro,
            sep,
            [
                MenuItem("Show purchases", "", tvm.functionId(showPurchases)),
                MenuItem("Add new purchase", "", tvm.functionId(addPurchase)),
                MenuItem("Delete purchase", "", tvm.functionId(deletePurchase))
            ]
        );
    }

    function addPurchase(uint32 index) public {
        index = index;
        Terminal.input(tvm.functionId(addPurchase_), "Enter product name:", false);
    }

    function addPurchase_(string value) public {
        m_productTitle = value;
        Terminal.input(tvm.functionId(addPurchase__), "Enter the number of products:", false);
    }

    function addPurchase__(string value) public {
        optional(uint) none;

        (uint amount,) = stoi(value);
        uint32 productsAmount = uint32(amount);

        IShoppingList(m_shoppingListAddress).addPurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: none,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onErrorListAction)
            }(m_productTitle, productsAmount);
    }
}