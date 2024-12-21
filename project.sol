// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EduFiInvestment {
    struct Investment {
        uint256 amount;
        uint256 timestamp;
    }

    struct Student {
        string name;
        string course;
        uint256 fundsRequired;
        uint256 fundsRaised;
        address payable wallet;
    }

    address public owner;
    uint256 public studentCount = 0;

    mapping(uint256 => Student) public students;
    mapping(address => Investment[]) public investments;

    event StudentAdded(uint256 studentId, string name, string course, uint256 fundsRequired);
    event FundInvested(address indexed investor, uint256 studentId, uint256 amount);
    event FundsWithdrawn(uint256 studentId, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addStudent(
        string memory _name,
        string memory _course,
        uint256 _fundsRequired,
        address payable _wallet
    ) public onlyOwner {
        require(_fundsRequired > 0, "Funds required must be greater than zero");

        students[studentCount] = Student({
            name: _name,
            course: _course,
            fundsRequired: _fundsRequired,
            fundsRaised: 0,
            wallet: _wallet
        });

        emit StudentAdded(studentCount, _name, _course, _fundsRequired);
        studentCount++;
    }

    function invest(uint256 _studentId) public payable {
        require(_studentId < studentCount, "Invalid student ID");
        require(msg.value > 0, "Investment amount must be greater than zero");

        Student storage student = students[_studentId];
        require(student.fundsRaised < student.fundsRequired, "Funding goal already met");

        uint256 amountToInvest = msg.value;
        if (student.fundsRaised + amountToInvest > student.fundsRequired) {
            amountToInvest = student.fundsRequired - student.fundsRaised;
            payable(msg.sender).transfer(msg.value - amountToInvest); // Refund excess
        }

        student.fundsRaised += amountToInvest;
        student.wallet.transfer(amountToInvest);

        investments[msg.sender].push(Investment({
            amount: amountToInvest,
            timestamp: block.timestamp
        }));

        emit FundInvested(msg.sender, _studentId, amountToInvest);
    }

    function getInvestments(address _investor) public view returns (Investment[] memory) {
        return investments[_investor];
    }

    function getStudentDetails(uint256 _studentId)
        public
        view
        returns (string memory, string memory, uint256, uint256, address)
    {
        require(_studentId < studentCount, "Invalid student ID");
        Student memory student = students[_studentId];
        return (student.name, student.course, student.fundsRequired, student.fundsRaised, student.wallet);
    }
}
