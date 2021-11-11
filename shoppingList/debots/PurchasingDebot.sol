pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../../base/Menu.sol";
import "InteractionShoppingListDebot.sol";

contract PurchasingDebot is InteractionShoppingListDebot {

    uint32 private m_productId;

    function listActionsMenu() internal override {
        string sep = '----------------------------------------';
        string intro = menuIntro();
        Menu.select(
            intro,
            sep,
            [
                MenuItem("Show purchases", "", tvm.functionId(showPurchases)),
                MenuItem("Confirm purchase", "", tvm.functionId(confirmPurchase)),
                MenuItem("Delete purchase", "", tvm.functionId(deletePurchase))
            ]
        );
    }

    function confirmPurchase(uint32 index) public {
        index = index;
        if (m_summary.countUnpaid + m_summary.countPaid > 0) {
            Terminal.input(tvm.functionId(confirmPurchase_), "Enter purchase id:", false);
        } else {
            Terminal.print(0, "There are no purchases to confirm in the list yet");
            listActionsMenu();
        }
    }

    function confirmPurchase_(string value) public {
        (uint id,) = stoi(value);
        m_productId = uint32(id);
        Terminal.input(tvm.functionId(confirmPurchase__), "Enter the total price of products in the selected purchase:", false);
    }

    function confirmPurchase__(string value) public {
        optional(uint) none;

        (uint price,) = stoi(value);
        uint32 productsPrice = uint32(price);

        IShoppingList(m_shoppingListAddress).confirmPurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: none,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onErrorListAction)
            }(m_productId, productsPrice);
    }
}