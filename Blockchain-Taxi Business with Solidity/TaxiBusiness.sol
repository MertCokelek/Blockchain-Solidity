pragma solidity >= 0.4.0;

contract TaxiBusiness {

    struct participant{
        address payable Address;
        uint Balance;
    }
    
    participant[9] public Participants; // Max. no. = 9
    uint ParticipantCount;      // Current participant number
    uint LastPaymentDate_Participants; // Holds last payment dates of the participants.


    address payable manager;
    

    address payable Taxi_Driver;
    uint public DriverBalance;
    uint DriverSalary;
    uint LastPaymentDate_Taxi;      // Check if at least 1 month passed since last payment.
    
    // These are only for proposals. Depending of the majority, they can be accepted or rejected.
    address payable proposed_driver;
    uint proposed_driver_salary;
    
    address payable dealer;
    uint public DealerBalance;
 
 
    uint public ContractBalance;
    uint FixedExpenses;
    uint participationFee;
    uint LastPaymentDate_Expenses; // used to check if the dealer is paid once each 6 months


    // These 6 variables are for BuyCar Propose.
    // In CarProposeToBusiness, these variables are set.
    // If majority and required money are satisfied, these variables will be used in PurchaseCar() / RepurchaseCar().
    string Proposed_CarID; 
    uint Proposed_CarPrice_buy;
    uint Proposed_CarPrice_repurchase;
    uint Proposed_OfferValidTime_buy;
    uint Proposed_OfferValidTime_repurchase;
    uint ApprovalStatus; // Counts positive votes for a proposal.
    bool contract_has_car;
    
    // Information of owned car.
    string CarID;
    uint CarPrice_buy;
    uint CarPrice_repurchase;
    

    // ------------------------- MODIFIERS -------------------------
    modifier onlyParticipant {
        bool participantExists = false;
        for(uint i = 0; i < 9; i++){
            if(msg.sender == Participants[i].Address){
                participantExists = true;
            }
        }
        require(participantExists == true, "Only participants can call this function.");
        _;
    }
    
    modifier onlyManager {
        require(msg.sender == manager, "Only Manager can call this function.");
        _;
    }
    
    modifier onlyCarDealer {
        require(msg.sender == dealer, "Only Car Dealer can call this function.");
       _;
    }
    
    modifier onlyDriver {
        require(msg.sender == Taxi_Driver, "Only Taxi Driver can call this function.");
        _;
    }
    
    mapping(address => bool) participants_approved;
    // Helper mapping, which is used for approval status.
    // This mapping makes users use only one vote(approve).
    // It is set after every purpose, and reset after every event.
    

    // ------------------------- THE OBLIGATORY FUNCTIONS -------------------------
    constructor () public payable {
        participationFee = 100 ether;
        FixedExpenses = 10 ether;
        ParticipantCount = 0;
        manager = msg.sender;
        contract_has_car = false;
    }
    
    function Join() external payable { 
    
        // Check if an account already is a participant.
        bool already_joined = false;
        for(uint i = 0; i < 9; i++){
            if(Participants[i].Address == msg.sender){
                already_joined = true;
            }
        }
        require(already_joined == false, "Already Participated.");
        require(ParticipantCount < 9, "Participant limit exceeded.");
        
        // Check for balance of the canditate.
        require (msg.value == participationFee, "Participation Fee is 100 ether. Check the value.");

        // Add new participant to the list.
        Participants[ParticipantCount].Address = msg.sender;
        Participants[ParticipantCount++].Balance = 0 ether; // Initially, zero balances given to participants. Because their personal assets are not our concern.
       
        // Update the Contract Balance.
        ContractBalance += participationFee;
        participants_approved[msg.sender] = false; // Initially, no one votes for anything.
    }

    function SetCarDealer(address payable _dealer) public onlyManager {
        // Assign the parameter to the dealer address.
        dealer = _dealer;
        DealerBalance = 0;
    }
    
    function CarProposeToBusiness(string memory _CarID, uint _CarPrice, uint _offerTime) public onlyCarDealer {
        Proposed_CarID = _CarID;
        Proposed_CarPrice_buy = _CarPrice * 1 ether;
        Proposed_OfferValidTime_buy = now + _offerTime * 1 days;
        ApprovalStatus = 0;
    }
    
    function ApprovePurchaseCar() public onlyParticipant{
        bool already_approved = participants_approved[msg.sender];
        require(already_approved == false, "Participant already approved once.");
        participants_approved[msg.sender] = true;
        ApprovalStatus += 1;
    }
    
    function PurchaseCar() public payable onlyManager {
        
        require(Proposed_OfferValidTime_buy >= now, "Offer Time for Buying is passed.");
        
        // Check for %50 +1 ApprovalStatus.
        require(ApprovalStatus > ParticipantCount/2, "Majority not achieved.");
        require(ContractBalance >= CarPrice_buy, "Contract does not have enough money.");
        
        CarID = Proposed_CarID;
        CarPrice_buy = Proposed_CarPrice_buy;

        ApprovalStatus = 0;

        ContractBalance -= CarPrice_buy;
        DealerBalance += CarPrice_buy;

        // Reset the approval status to be able to use the same array later.
        for(uint i = 0; i < 9; i++){
            participants_approved[Participants[i].Address] = false;
        }
        contract_has_car = true;
    }
    
    function RepurchaseCarPropose(uint _carPrice, uint _offerTime) public onlyCarDealer {
        require(_carPrice <= DealerBalance, "Dealer can not efford to take the car back.");
        CarPrice_repurchase = _carPrice * 1 ether;
        Proposed_OfferValidTime_repurchase = now + _offerTime * 1 days;
        ApprovalStatus = 0;
    }
    
    function ApproveSellProposal() public onlyParticipant  {
        bool already_approved = participants_approved[msg.sender];
        require(already_approved == false, "Participant already approved once.");
        participants_approved[msg.sender] = true;
        ApprovalStatus += 1;
    }
    
    function RepurchaseCar() public payable onlyCarDealer {
        require(Proposed_OfferValidTime_repurchase >= now, "Valid time passed.");
        require(ApprovalStatus > ParticipantCount / 2, "Majority not achieved.");

        ContractBalance += CarPrice_repurchase;
        DealerBalance -= CarPrice_repurchase;

        // Reset the approval status to be able to use the same array later.
        for(uint i = 0; i < 9; i++){
            participants_approved[Participants[i].Address] = false;
        }
        ApprovalStatus = 0;
        contract_has_car = false;
        CarID = "";

    }
    
    function ProposeDriver(address payable _driver, uint _driverSalary) public onlyManager {
        proposed_driver = _driver;
        proposed_driver_salary = _driverSalary * 1 ether;
        ApprovalStatus = 0;
    }
    
    function ApproveDriver() public onlyParticipant {
        bool already_approved = participants_approved[msg.sender];
        require(already_approved == false, "Participant already approved once.");
        participants_approved[msg.sender] = true;
        ApprovalStatus += 1;
    }
    
    function SetDriver() public onlyManager{
        require(ApprovalStatus > ParticipantCount / 2, "Majority not achieved");
        Taxi_Driver = proposed_driver;
        DriverSalary = proposed_driver_salary * 1 ether;
        for(uint i = 0; i < 9; i++){
            participants_approved[Participants[i].Address] = false;
        }
        ApprovalStatus = 0;
        
    }
    
    function FireDriver() public onlyManager {
        require(Taxi_Driver != address(0), "There is no driver to fire.");
        DriverBalance += DriverSalary;
        ContractBalance -= DriverSalary;
        Taxi_Driver = address(0);
        DriverSalary = 0;
        
    }
    
    function GetCharge() public payable {
        // Check if a taxi and a driver exists.
        require(contract_has_car && Taxi_Driver != address(0), "No charge.");
        ContractBalance += msg.value;
    }
    
    
    function ReleaseSalary() public payable onlyManager {
        bool cond1 = Taxi_Driver != address(0);
        bool cond2 = ContractBalance >= DriverSalary;
        require(cond1 && cond2);
        
        require(now - LastPaymentDate_Taxi > 30 * 1 days, "At least 1 month must pass for next payment.");

        LastPaymentDate_Taxi = now;
        
        // Make the payment between the balances.
        ContractBalance -= DriverSalary;
        DriverBalance += DriverSalary;
    }
    
    function GetSalary() public payable onlyDriver {
        require(DriverBalance > 0, "You have no money to withdraw.");
        address(this).transfer(DriverBalance);
        DriverBalance = 0;
    }
    
    function CarExpenses() public payable onlyManager {
        // Dealer is needed for paying expenses.
        require(dealer != address(0));
        
        require(now - LastPaymentDate_Expenses > 180* 1 days, "Less than 6 months passed since last payment.");
        
        if(ContractBalance >= FixedExpenses){
            LastPaymentDate_Expenses = now;
            ContractBalance -= FixedExpenses;
            DealerBalance += FixedExpenses; 
        }
        require(ContractBalance >= FixedExpenses, "Contract can not efford to pay expenses.");


    }
    function PayDividend() public onlyManager{
        // Expenses.
        if(now - LastPaymentDate_Expenses > 180 *1 days){
            ContractBalance -= FixedExpenses;
            LastPaymentDate_Expenses = now;
        }
        
        // Driver Salary payment.
        if(Taxi_Driver != address(0) && now - LastPaymentDate_Taxi > 180* 1 days){
            LastPaymentDate_Taxi = now;
            ContractBalance -= DriverSalary;
        }

        if(now - LastPaymentDate_Participants > 180 * 1 days){
                    
            // Check for balance/outcome.
            if(ContractBalance > 0){
            // Payments for Participants
                
                LastPaymentDate_Participants = now;
        
                // divide the profit
                uint moneyPerParticipant = (ContractBalance) / ParticipantCount;
            
                // transfer the single profit amount to the local balance of each participant
                for (uint i = 0; i < ParticipantCount; i++) {
                    Participants[i].Balance += moneyPerParticipant;
                    ContractBalance -= moneyPerParticipant;
                }
            }

        }
    }
    
    function GetDividend() public payable onlyParticipant {
        uint withdraw = 0;
        // check if participants have balance to withdraw
        for(uint i = 0; i < 9; i++){
            if(Participants[i].Address == msg.sender){
                withdraw = Participants[i].Balance;
                address(this).transfer(withdraw);
                Participants[i].Balance = 0;
            }
        }
    }
    function () payable external{
        
    }
}