// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// contract EventToken is ERC20 {
//     constructor(
//         string memory tokenName,
//         string memory symbol,
//         uint256 supply,
//         address owner
//     ) ERC20(tokenName, symbol) {
//         _mint(owner, supply * 10**decimals());
//     }
// }

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Marketplace {
    uint256 internal ticketLengths = 0;
    address internal cUsdTokenAddress =
        0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct EventBrite {
        address payable owner;
        string name;
        string image;
        string description;
        string venue;
        uint256 price;
        uint256 sold;
        bool openForSale;
        // EventToken eventToken;
    }

    enum TicketStatus {
        OnSale,
        // SaleCancelled,
        SoldOut
    }
    TicketStatus public TicketState;

    event newTicket(address indexed buyer, uint index);
    event Transfer(address indexed ticketSeller, uint index, uint ticketPrice, address indexed ticketBuyer);

    modifier onlyOwner(uint _index){
        require(msg.sender == eventTicket[_index].owner, "Sorry, you are not the Owner");
        _;
    }

    modifier ticketPrice() {
        require(msg.value > 0, "Zero Ether can't be sent to this address");
        _;
    }

    // modifier notAddressZero() {
    //     revert(0x0 != msg.sender);
    //     _;
    // }

    mapping(uint256 => EventBrite) internal eventTicket;

    function updatedTicket(
        string memory _name,
        string memory _image,
        string memory _description,
        string memory _venue,
        uint256 _price,
        bool _openForSale
    ) public {
        uint256 _sold = 0;
        // EventToken _eventToken = new EventToken(EventToken, "ETK", address(this));

        eventTicket[ticketLengths] = EventBrite(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _venue,
            _price,
            _sold,
            _openForSale
        );
        ticketLengths++;
        emit newTicket(msg.sender, ticketLengths);
    }

    function updatedTicketPrice(uint _index, uint _price) public payable onlyOwner(_index) {
        eventTicket[_index].price = _price;
    }

    function newVenue(string calldata _venue, uint _price) public  {
        eventTicket[_price].venue = _venue;
    }

    function readProduct(uint256 _index)
        public
        view
        returns (
            address payable,
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            bool
            // EventToken
        )
    {
        return (
            eventTicket[_index].owner,
            eventTicket[_index].name,
            eventTicket[_index].image,
            eventTicket[_index].description,
            eventTicket[_index].venue,
            eventTicket[_index].price,
            eventTicket[_index].sold,
            eventTicket[_index].openForSale
            // eventTicket[_index].eventToken
        );
    }

    function buyTicket(uint256 _index) public ticketPrice payable {
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                eventTicket[_index].owner,
                eventTicket[_index].price
            ),
            "Transfer failed."
        );
        eventTicket[_index].sold++;

        TicketState == TicketStatus.OnSale;

        emit Transfer(eventTicket[_index].owner, _index, eventTicket[_index].price, msg.sender);
    }

    function getTicketsLength() public view returns (uint256) {
        return (ticketLengths);
    }

    // function getTokenAddress(uint _index) public view returns(address) {
    //     return address(eventTicket[_index].eventToken);
    // }
}
