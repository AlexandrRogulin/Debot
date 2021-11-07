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
import "InterfacesAndStructs.sol";

abstract contract AbsDebot is Debot{
    TvmCell m_code; // contract code
    TvmCell m_data; // contract data
    TvmCell m_stateInit; // contract initial state

    address m_address;  // contract address
    PurchasesSummary m_summary; // summary for existing purchases
    uint256 m_masterPubKey; // User pubkey
    address m_msigAddress;  // User wallet address

    uint32 INITIAL_BALANCE =  200000000;  // Initial SHOPPINGLIST contract balance


    function setTodoCode(TvmCell code, TvmCell data) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        m_code = code;
        m_data = data;

        m_stateInit = tvm.buildStateInit(m_code, m_data);
    }


    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
    }

    function onSuccess() public {
        _getSummary(tvm.functionId(SetSummary));
    }

    function _getSummary(uint32 answerId) private view {
        optional(uint256) none;
        IShoppingList(m_address).getSummary{
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

    function SetSummary(PurchasesSummary summary) public {
        m_summary = summary;
        _menu();
    }

    function start() virtual public override {}

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() virtual public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {}

    function savePublicKey(string value) public {
        (uint res, bool status) = stoi("0x"+value);
        if (status) {
            m_masterPubKey = res;

            Terminal.print(0, "Checking if you already have a SHOPPINGLIST list ...");
            TvmCell deployState = tvm.insertPubkey(m_stateInit, m_masterPubKey);
            m_address = address.makeAddrStd(0, tvm.hash(deployState));
            Terminal.print(0, format( "Info: your SHOPPINGLIST contract address is {}", m_address));
            Sdk.getAccountType(tvm.functionId(checkStatus), m_address);
        } else {
            Terminal.input(tvm.functionId(savePublicKey),"Wrong public key. Try again!\nPlease enter your public key",false);
        }
    }

    function checkStatus(int8 acc_type) public {
        if (acc_type == 1) { // acc is active and  contract is already deployed
            _getSummary(tvm.functionId(SetSummary));

        } else if (acc_type == -1)  { // acc is inactive
            Terminal.print(0, "You don't have a SHOPPINGLIST list yet, so a new contract with an initial balance of 0.2 tokens will be deployed");
            AddressInput.get(tvm.functionId(creditAccount),"Select a wallet for payment. We will ask you to sign two transactions");

        } else  if (acc_type == 0) { // acc is uninitialized
            Terminal.print(0, format(
                "Deploying new contract. If an error occurs, check if your SHOPPINGLIST contract has enough tokens on its balance"
            ));
            deploy();

        } else if (acc_type == 2) {  // acc is frozen
            Terminal.print(0, format("Can not continue: account {} is frozen", m_address));
        }
    }

    function creditAccount(address value) public {
        m_msigAddress = value;
        optional(uint256) pubkey = 0;
        TvmCell empty;
        Transactable(m_msigAddress).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(waitBeforeDeploy),
            onErrorId: tvm.functionId(onErrorRepeatCredit)  // Just repeat if something went wrong
        }(m_address, INITIAL_BALANCE, false, 3, empty);
    }

    function onErrorRepeatCredit(uint32 sdkError, uint32 exitCode) public {
        creditAccount(m_msigAddress);
    }


    function waitBeforeDeploy() public {
        Sdk.getAccountType(tvm.functionId(checkIfAccountUnInit), m_address);
    }

    function checkIfAccountUnInit(int8 acc_type) public {
        if (acc_type ==  0) { // Check if account has tokens on its balance
            // If its true we need to deploy it
            deploy();
        } else {
            waitBeforeDeploy();
        }
    }

    function deploy() private view {
        TvmCell image = tvm.insertPubkey(m_stateInit, m_masterPubKey);
        optional(uint256) none;
        TvmCell deployMsg = tvm.buildExtMsg({
            abiVer: 2,
            dest: m_address,
            callbackId: tvm.functionId(onSuccess),
            onErrorId:  tvm.functionId(onErrorRepeatDeploy),    // Just repeat if something went wrong
            time: 0,
            expire: 0,
            sign: true,
            pubkey: none,
            stateInit: image,
            call: {HasConstructorWithPubKey, m_masterPubKey}
        });
        tvm.sendrawmsg(deployMsg, 1);
    }


    function onErrorRepeatDeploy(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, "SOME ERROR. WE ARE TRYING DEPLOY AGAIN!");
        deploy();
    }

    function _menu() virtual internal;
}