pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "InitializingShopListDebot.sol";

abstract contract InteractionShoppingListDebot is InitializingShopListDebot {

    function menuIntro() internal returns (string) {
        string intro;
        uint32 totalCount = m_summary.countUnpaid + m_summary.countPaid;
        if (totalCount == 0) {
            intro = "Shopping list is empty";
        } else {
            intro = format("You have {} purchases", totalCount);
            if (m_summary.countUnpaid != 0) {
                intro = format("{} ({} unpaid)", intro, m_summary.countUnpaid);
            }
            if (m_summary.countPaid != 0) {
                intro = format("{} ({} paid with total price {} cr.)", intro, m_summary.countPaid, m_summary.totalPaid);
            }
        }
        return intro;
    }

    function showPurchases(uint32 index) public view {
        index = index;
        optional(uint256) none;
        IShoppingList(m_shoppingListAddress).getPurchases{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showPurchases_),
            onErrorId: 0
        }();
    }

    function showPurchases_(Purchase[] purchases) public {
        string confirmationSymbol;
        string priceInfo;
        if (purchases.length > 0 ) {
            Terminal.print(0, "Your shopping list:");
            for (uint32 i = 0; i < purchases.length; i++) {
                Purchase purchase = purchases[i];
                if (purchase.isConfirmed) {
                    confirmationSymbol = "+";
                    priceInfo = format(" with total price {} cr.", purchase.price);
                } else {
                    confirmationSymbol = "-";
                    priceInfo = "";
                }
                Terminal.print(0, format("[{}]{} {} units of {}{} | added at {} |",
                    purchase.id, confirmationSymbol, purchase.quantity, purchase.title, priceInfo, purchase.dataCreated));
            }
        }
        listActionsMenu();
    }

    function deletePurchase(uint32 index) public {
        index = index;
        if (m_summary.countUnpaid + m_summary.countPaid > 0) {
            Terminal.input(tvm.functionId(deletePurchase_), "Enter purchase id:", false);
        } else {
            Terminal.print(0, "There are no purchases to remove in the list yet");
            listActionsMenu();
        }
    }

    function deletePurchase_(string value) public view {
        optional(uint) none;
        (uint productId,) = stoi(value);

        IShoppingList(m_shoppingListAddress).deletePurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: none,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onErrorListAction)
            }(uint32(productId));
    }

	function onErrorListAction(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
        listActionsMenu();
    }
}