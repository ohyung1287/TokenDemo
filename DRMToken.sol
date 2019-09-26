pragma solidity ^0.4.25;
import './ERC721BasicToken.sol';
import './Ownable.sol';


contract DRMToken is ERC721BasicToken, Ownable{
     string public tokenName = "Digital Right Token";
    string public symbol = "DRM";
    struct Artwork{
        string name;
        string artist;
        string description;
        string IPFS;// link of image 
        uint64 timestamp;
    }
    uint _artworkId = 0;
    Artwork[] public artworks; 
    mapping(uint256 => bool) internal isCreated;
    mapping(address => bool) public registeredArtists;
    mapping(uint256 => uint256) public tokenPrices;
    // mapping(string => uint256[]) public IPFStoID; // filter out a list of ID with same image 
    uint public tokenCount;
    function setTokenPrice(uint _tokenId, uint _price) external onlyOwner{
        require(_exists(_tokenId));
        tokenPrices[_tokenId] = _price;
    }
    // function findSimilar(string _IPFS) external returns(uint256[] artworks) {
    //     return IPFStoID[_IPFS];
    // }
    function artistRegister(address _artist, string _name)external onlyOwner{ 
        registeredArtists[_artist] = true;
    }
    function isRegisteredArtist()external returns(bool){
        address sender= msg.sender;
        return registeredArtists[sender];
    }
    function getTokenName()external returns(string){
        return tokenName;
    }
    // Creates artwork as private token()
    function ArtworkCreation(string _name, string _artist, string _description, string _IPFS, uint _deployNum) public { // When artist upload a new artwork to platform
        require(_deployNum > 0);
        require(registeredArtists[msg.sender]);
        for(uint i=0; i < _deployNum ; i++){
            Artwork memory _artwork = Artwork({
                name:_name,
                artist:_artist,
                description:_description,
                IPFS:_IPFS,
                timestamp:uint64(now)
            });
            uint256 id = artworks.push(_artwork) - 1;
            tokenPrices[id] = 10000000000000000;// default price =0.01 eth
            isCreated[id] = true;
            // IPFStoID[_IPFS].push(id); // add image into mapping
        }
    }
    function requestBuy(uint256 _tokenId) payable external ifNotPaused {
        require(msg.value >= tokenPrices[_tokenId]);
        require(isCreated[_tokenId]);
        // require(TokenMint(msg.sender,_tokenId));
        _mint(msg.sender, _tokenId); //Mints the token ID of the newest placeholder structure to that wallet address.
        tokenCount++; //adds one to total token count
    }
    function purchaseInPeriod(uint _dateStart, uint _dateEnd, uint _tokenId)payable external returns(uint){// only sell in timeperiod
        if(now >= _dateStart && now <= _dateEnd){
            require(msg.value >= tokenPrices[_tokenId]);
            TokenMint(msg.sender, _tokenId);
        }
    }
    modifier TokenMint(address _wallet, uint256 _tokenId){
        _mint(_wallet, _tokenId); //Mints the token ID of the newest placeholder structure to that wallet address.
        tokenCount++; //adds one to total token count
        _;
    }

}