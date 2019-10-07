const express = require("express");
const app = express();
const cors = require("cors");
const Web3 = require("web3");
const abi = require("./abi");
const fetch = require("node-fetch");
const Tx = require("ethereumjs-tx");

const bodyParser = require("body-parser");
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

//envSetup
let web3;
let DRM_address = "0x71bb75a1f6d291d044bc5cc678c7126f07ee9667";
let DRM_owner = "0x5efDD3CAb3c3Ea3D1725B8EaF340Cc8d5a9B7547";
let DRM_ownerKey =
  "45F93E7A6CF774228519708AA97529A9CE2A663E26E67F183FE49BB9C90D468D";

var infuraLink =
  "https://rinkeby.infura.io/v3/7a19de34892e4625b8464eac960146b7";
web3 = new Web3(new Web3.providers.HttpProvider(infuraLink));
let DRM = new web3.eth.Contract(abi, DRM_address);
app.get("/getTokenName/", async (req, res) => {
  var name = await DRM.methods.getTokenName().call();
  res.send(name);
});
app.post("/artistRegister/", async (req, res) => {
  try {
    var address = req.body.address;
    var name = req.body.name;

    var transfer = await DRM.methods.artistRegister(address, name).encodeABI();
    console.log(`registering artist name=${name}, address=${address}`);
    await sendTxn(transfer);
    res.sendStatus(200);
  } catch (err) {
    console.log(err);
    res.send(err);
  }
});
app.post("/purchaseInPeriod/", async (req, res) => {
  try {
    var dateStart = req.query.dateStart;
    var dateEnd = req.query.dateEnd;
    var tokenId = req.query.tokenId;
    var transfer = await DRM.methods
      .purchaseInPeriod(dateStart, dateEnd, tokenId)
      .encodeABI();
    await sendTxn(transfer);
    res.sendStatus(200);
  } catch (err) {
    console.log(err);
    res.send(err);
  }
});
async function sendTxn(transfer) {
  var count = await web3.eth.getTransactionCount(DRM_owner);
  var price = await getGasPrice();
  price = price.toString(16);
  rawTransaction = {
    from: DRM_owner,
    nonce: web3.utils.toHex(count),
    gasPrice: 10000000000,
    gasLimit: 210000,
    to: DRM_address,
    value: "0x0",
    data: transfer,
    chainId: 0x04
  };
  var keyStr = DRM_ownerKey;

  var privKey = Buffer.from(keyStr, "hex");
  var tx = new Tx(rawTransaction);
  tx.sign(privKey);
  var serializedTx = tx.serialize();
  var txn = await web3.eth.sendSignedTransaction(
    "0x" + serializedTx.toString("hex")
  );
  console.log(txn);
}
async function getGasPrice() {
  var price;
  try {
    var fetchJson = await fetch(
      "https://www.etherchain.org/api/gasPriceOracle"
    );
    var priceJson = await fetchJson.json();
    price = parseFloat(priceJson.standard) + 1;
    price *= 1000000000;
    price += 1000000000;
  } catch (err) {
    console.log(err);
    price = 15000000000;
  }
  return price;
}
app.listen(8080, () => console.log("Listening on port 8080..."));
