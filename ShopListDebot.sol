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
import "FillDebot.sol";
import "DoShoppingDebot.sol";

// This is the main debot for user itneraction
contract ShopListDebot is Debot, AbsDebot, FillDebot, DoShoppingDebot{
    function start() public override(Debot, AbsDebot, FillDebot, DoShoppingDebot) {
        Terminal.input(tvm.functionId(savePublicKey),"Please enter your public key",false);
    }

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override(Debot, AbsDebot, FillDebot, DoShoppingDebot) view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "SHOPPINGLIST DeBot";
        version = "0.2.0";
        publisher = "TON Labs";
        key = "TODO list manager";
        author = "TON Labs";
        support = address.makeAddrStd(0, 0x66e01d6df5a8d7677d9ab2daf7f258f1e2a7fe73da5320300395f99e01dc3b5f);
        hello = "Hi, i'm a SHOPPINGLIST DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
    }

    function getRequiredInterfaces() public view override(Debot, FillDebot, DoShoppingDebot) returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, ConfirmInput.ID ];
    }
    
    // =================================================================================
    function _menu() override(AbsDebot, FillDebot, DoShoppingDebot) internal{
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You have {}/{} (paid/unpaid) purchases and you spent {} money",
                    m_summary.paidPurchases,
                    m_summary.unpaidPurchases,
                    m_summary.spandMoney
            ),
            sep,
            [
                MenuItem("Add new purchase","",tvm.functionId(addPurchase)),
                MenuItem("Show all my purchases","",tvm.functionId(showMyShopList)),
                MenuItem("Delete some purchase","",tvm.functionId(deleteSomePurchase)),
                MenuItem("Make purchase","",tvm.functionId(makePurchase))
            ]
        );
    }
}