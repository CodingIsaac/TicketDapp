// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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
        uint256 ticketsAvailable;
        TicketStatus status;
        // EventToken eventToken;
    }

    enum TicketStatus {
        UNDEFINED,
        OnSale,
        SaleCancelled,
        SoldOut
    }
    TicketStatus public TicketState;

    event newTicket(address indexed buyer, uint256 index);
    event Transfer(
        address indexed ticketSeller,
        uint256 index,
        uint256 ticketPrice,
        address indexed ticketBuyer
    );

    modifier onlyOwner(uint256 _index) {
        require(
            msg.sender == eventTicket[_index].owner,
            "Sorry, you are not the Owner"
        );
        _;
    }

    mapping(uint256 => EventBrite) private eventTicket;

    /**
        * @dev allow users to create a sale of tickets for an upcoming event
        * @notice input data needs to contain valid/not empty values
     */
    function createEventTicket(
        string calldata _name,
        string calldata _image,
        string calldata _description,
        string calldata _venue,
        uint256 _price,
        uint256 _ticketsAvailable
    ) public {
        require(bytes(_name).length > 0, "Empty name");
        require(bytes(_image).length > 0, "Empty image");
        require(bytes(_description).length > 0, "Empty description");
        require(bytes(_venue).length > 0, "Empty venue");
        require(_ticketsAvailable > 0, "Invalid number for number of tickets available");
        uint256 _sold = 0;
        uint256 eventId = ticketLengths;
        ticketLengths++;
        eventTicket[eventId] = EventBrite(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _venue,
            _price,
            _sold,
            _ticketsAvailable,
            TicketStatus.OnSale
        );
        emit newTicket(msg.sender, eventId);
    }

    /**
        * @dev allow owner of a ticket's sale to update the price of a ticket
     */
    function updatedTicketPrice(uint256 _index, uint256 _price)
        public
        payable
        onlyOwner(_index)
    {
        eventTicket[_index].price = _price;
    }

    /**
        * @dev allow owner of a ticket's sale to update the venue of the event
     */
    function newVenue(string calldata _venue, uint256 _index)
        public
        onlyOwner(_index)
    {
        eventTicket[_index].venue = _venue;
    }

    /**
        * @dev allow owner of a ticket's sale to cancel the sale of tickets
     */
    function cancelTicketSale(uint256 _index)
        public
        onlyOwner(_index)
    {
        eventTicket[_index].status = TicketStatus.SaleCancelled;
    }

    function readEventTicket(uint256 _index)
        public
        view
        returns (EventBrite memory)
    {
        return (eventTicket[_index]);
    }


    /**
        * @dev allow users to buy tickets of an upcoming event
        * @param amount the number of tickets to buy
        * @notice Tickets can only be bought if they haven't sold out yet
        * @notice amount must be less or equal to the number of tickets currently available
     */
    function buyTicket(uint256 _index, uint amount) public payable {
        EventBrite storage currentEvent = eventTicket[_index];
        require(currentEvent.ticketsAvailable >= amount, "Not enough tickets available to fulfill this order");
        require(currentEvent.owner != msg.sender, "You can't buy your own tickets");
        require(currentEvent.status == TicketStatus.OnSale, "Tickets aren't on sale for this event");
                require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                currentEvent.owner,
                currentEvent.price
            ),
            "Transfer failed."
        );
        uint newSoldAmount = currentEvent.sold + amount;
        currentEvent.sold = newSoldAmount;
        uint newTicketsAvailable = currentEvent.ticketsAvailable - amount;
        currentEvent.ticketsAvailable = newTicketsAvailable;
        if(currentEvent.ticketsAvailable == 0){
            currentEvent.status = TicketStatus.SoldOut;
        }
        emit Transfer(
            currentEvent.owner,
            _index,
            currentEvent.price,
            msg.sender
        );
    }

    function getTicketsLength() public view returns (uint256) {
        return (ticketLengths);
    }
}
