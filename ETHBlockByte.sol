pragma solidity ^0.4.14;

contract ETHBlockByte {
    bytes32 public name = 'ETHBlockByte';
    address public owner;
    uint256 public max_fee;
    uint256 public create_block;
    bytes1 public last_result;
    bytes1 private block_pointer;
    bytes1 private byte_pointer;

    event Balance(uint256 _balance);
    event Play(address indexed _sender, bytes1 _start, bytes1 _end, bytes1 _result, bool _winner, uint256 _time);
    event Withdraw(address indexed _sender, uint256 _amount, uint256 _time);
    event Destroy();

    function ETHBlockByte() public {
        owner = msg.sender;
        create_block = block.number; 
        block_pointer = 0xff;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isPaid() {
        require(msg.value > 0 && msg.value <= max_fee);
        _;
    }

    function play(bytes1 _start, bytes1 _end) public payable isPaid returns (bool) {
        bool winner = false;
        // cast start and end to uint8
        uint8 start = uint8(_start);
        uint8 end = uint8(_end);
        // check range start to end
        if (start == 0 || end < start) {
            revert();
        }
        // get result block hash
        bytes32 block_hash = block.blockhash(block.number - uint8(block_pointer));
        // get result block byte
        last_result = block_hash[uint8(byte_pointer) % 32];
        // case result to uint8
        uint8 result = uint8(last_result);
        // set new pointers for new play
        block_pointer = block_hash[31];
        if (block_pointer == 0x00) {
            block_pointer = 0xff;
        }
        byte_pointer = block_hash[0];
        // we are nice and always return 1 WEI in case of loser (sonerex)
        uint256 credit = 1;
        // check for winner, ZERO is HOUSE
        if (result > 0 && 
            result >= start &&
            result <= end) {
            winner = true;
            // there is a winner, calculate prize
            uint256 range = end - start + 1;
            uint256 percentage = 100 - (range * 100 / 255);
            uint256 prize = 0;
            if (percentage > 10) {
                prize = msg.value * (percentage - 10) / 100;
            }
            credit = msg.value + prize;
        }
        if (!msg.sender.send(credit)) {
            return false;
        }
        max_fee = this.balance / 4;
        Balance(this.balance);
        Play(msg.sender, _start, _end, last_result, winner, now);
        return true;
    }

    function withdraw(uint256 _credit) public isOwner returns (bool) {
        if (!owner.send(_credit)) {
            return false;
        }
        Withdraw(msg.sender, _credit, now);
        return true;
    }

    function destruct() public isOwner {
        Destroy();
        selfdestruct(owner);
    }

    function () public payable {
        max_fee = this.balance / 4;
        Balance(this.balance);
    }
}
