pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../../base/Debot.sol";
import "../../base/Terminal.sol";
import "../../base/AddressInput.sol";
import "../../base/ConfirmInput.sol";
import "../../base/Menu.sol";
import "../../base/Sdk.sol";

import "../interface/InterfaceAndStructs.sol";


abstract contract InitializingShopListDebot is Debot {

    bytes m_icon;
    TvmCell m_shoppingListCode;
    TvmCell m_shoppingListData;
    TvmCell m_shoppingListStateInit; // Shopping List contract code
    address m_shoppingListAddress; // Shopping List contract address
    PurchasesSummary m_summary; // Statistic summary purchase
    uint256 m_userPubKey; // User pubkey
    address m_walletAddress; // User wallet address

    uint32 INITIAL_BALANCE =  200000000; // Initial Shopping List contract balance


    function listActionsMenu() internal virtual {}

    function setShoppingListCode(TvmCell code, TvmCell data) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        m_shoppingListCode = code;
        m_shoppingListData = data;
        m_shoppingListStateInit = tvm.buildStateInit(m_shoppingListCode, m_shoppingListData);
    }

    function start() public override {
        Terminal.input(tvm.functionId(savePublicKey), "Please enter your public key", false);
    }

    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "initializing the shopping list DeBot";
        author = "Alexandr Rogulin";
        hello = "Hello! It's a Shopping List DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, AddressInput.ID, ConfirmInput.ID, Menu.ID ];
    }

    function savePublicKey(string value) public {
        (uint res, bool status) = stoi("0x" + value);
        if (status) {
            m_userPubKey = res;

            Terminal.print(0, "Checking if you already have a Shopping List ...");
            TvmCell deployState = tvm.insertPubkey(m_shoppingListStateInit, m_userPubKey);
            m_shoppingListAddress = address(tvm.hash(deployState));
            Terminal.print(0, format( "Info: your Shopping List contract address is {}", m_shoppingListAddress));
            Sdk.getAccountType(tvm.functionId(checkStatus), m_shoppingListAddress);

        } else {
            Terminal.input(tvm.functionId(savePublicKey), "Wrong public key. Try again!\nPlease enter your public key", false);
        }
    }

    function checkStatus(int8 acc_type) public {
        if (acc_type == 1) { // acc is active and  contract is already deployed
            _getSummary(tvm.functionId(setSummary));

        } else if (acc_type == -1) { // acc is inactive
            Terminal.print(0, "You don't have a Shopping List list yet, so a new contract with an initial balance of 0.2 tokens will be deployed");
            AddressInput.get(tvm.functionId(creditAccount), "Select a wallet for payment. We will ask you to sign two transactions");

        } else if (acc_type == 0) { // acc is uninitialized
            Terminal.print(0, "Deploying new contract. If an error occurs, check if your Shopping List contract has enough tokens on its balance");
            deploy();

        } else if (acc_type == 2) { // acc is frozen
            Terminal.print(0, format("Can not continue: account {} is frozen", m_shoppingListAddress));
        }
    }

    function creditAccount(address value) public {
        m_walletAddress = value;
        optional(uint256) none;
        TvmCell empty;
        Transactable(m_walletAddress).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(waitBeforeDeploy),
            onErrorId: tvm.functionId(onErrorRepeatCredit) // Just repeat if something went wrong
        }(m_shoppingListAddress, INITIAL_BALANCE, false, 3, empty);
    }

    function onErrorRepeatCredit(uint32 sdkError, uint32 exitCode) public {
        sdkError;
        exitCode;
        creditAccount(m_shoppingListAddress);
    }

    function waitBeforeDeploy() public  {
        Sdk.getAccountType(tvm.functionId(checkIfStatusIs0), m_shoppingListAddress);
    }

    function checkIfStatusIs0(int8 acc_type) public {
        if (acc_type ==  0) {
            deploy();
        } else {
            waitBeforeDeploy();
        }
    }

    function deploy() private view {
        TvmCell state = tvm.insertPubkey(m_shoppingListStateInit, m_userPubKey);
        optional(uint256) none;
        TvmCell deployMsg = tvm.buildExtMsg({ 
            abiVer: 2,
            dest: m_shoppingListAddress,
            callbackId: tvm.functionId(onSuccess),
            onErrorId:  tvm.functionId(onErrorRepeatDeploy), // Just repeat if something went wrong
            time: 0,
            expire: 0,
            sign: true,
            pubkey: none,
            stateInit: state,
            call: {HasConstructorWithPubKey, m_userPubKey}
        });
        tvm.sendrawmsg(deployMsg, 1);
    }

    function onSuccess() public view {
        _getSummary(tvm.functionId(setSummary));
    }

    function onErrorRepeatDeploy(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("ERROR: sdkError {}, exitCode {}", sdkError, exitCode));
    }

    function _getSummary(uint32 answerId) private view {
        optional(uint256) none;
        IShoppingList(m_shoppingListAddress).getSummary{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: 0
        }();
    }

    function setSummary(PurchasesSummary summary) public {
        m_summary = summary;
        listActionsMenu();
    }
}
