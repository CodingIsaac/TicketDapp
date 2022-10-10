import Web3 from 'web3'
import { newKitFromWeb3 } from '@celo/contractkit'
import BigNumber from "bignumber.js"
import marketPlaceAbi from '../contract/marketplace.abi.json'
import erc20Abi from "../contract/erc20.abi.json"

const ERC20_DECIMALS = 18
const MPContractAddress = "0xf0bcdbe275Dad16Afb0Cd716c9f1322eC5684235"
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1"

let kit
let contract
let products = []
let defaultAccount
let celoTestnetChainId=44787
let celoExplorer = "https://alfajores-blockscout.celo-testnet.org/"




const connectCeloWallet = async function () {
    if (window.celo) {
      try {
        notification("⚠️ Please approve this DApp to use it.")
        await window.celo.enable()
        notificationOff()
        const web3 = new Web3(window.celo)
        kit = newKitFromWeb3(web3)
  
        const accounts = await kit.web3.eth.getAccounts()
        kit.defaultAccount = accounts[0]
  
        contract = new kit.web3.eth.Contract(marketPlaceAbi, MPContractAddress)
      } catch (error) {
        notification(`⚠️ ${error}.`)
      }
    } else {
      notification("⚠️ Please install the CeloExtensionWallet.")
    }
  }


async function approve(_price) {
    const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)
  
    const result = await cUSDContract.methods
      .approve(MPContractAddress, _price)
      .send({ from: kit.defaultAccount })
    return result
  }

  document.querySelector("#marketplace").addEventListener("click", async (e) => {
    if (e.target.className.includes("buyBtn")) {
      const index = e.target.id
      notification("⌛ Waiting for payment approval...")
      try {
        await approve(products[index].price)
      } catch (error) {
        notification(`⚠️ ${error}.`)
      }

      notification(`⌛ Awaiting payment for "${products[index].name}"...`)
    try {
      const result = await contract.methods
        .buyProduct(index)
        .send({ from: kit.defaultAccount })
      notification(`🎉 You successfully bought "${products[index].name}".`)
      getProducts()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }
})



const getBalance = async function () {
    const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
    const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
    document.querySelector("#balance").textContent = cUSDBalance
  }

  window.addEventListener('load', async () => {
    notification("⌛ Loading...")
    await connectCeloWallet()
    await getBalance()
    notificationOff()
  });

  const getProducts = async function() {
    const _productsLength = await contract.methods.getProductsLength().call()
    const _products = []

    for (let i = 0; i < _productsLength; i++) {
        let _product = new Promise(async (resolve, reject) => {
          let p = await contract.methods.readProduct(i).call()
          resolve({
            index: i,
            owner: p[0],
            name: p[1],
            image: p[2],
            description: p[3],
            location: p[4],
            price: new BigNumber(p[5]),
            sold: p[6],
          })
        })
        _products.push(_product)
      }
      products = await Promise.all(_products)
      renderProducts()
    }

    document
  .querySelector("#newProductBtn")
  .addEventListener("click", async (e) => {
    const params = [
      document.getElementById("newProductName").value,
      document.getElementById("newImgUrl").value,
      document.getElementById("newProductDescription").value,
      document.getElementById("newVenue").value,
      new BigNumber(document.getElementById("newPrice").value)
    
      .shiftedBy(ERC20_DECIMALS)
      .toString()
    ]
    notification(`⌛ Adding "${params[0]}"...`)

    try {
         await contract.methods
          .writeProduct(...params)
          .send({ from: kit.defaultAccount })
      } catch (error) {
        notification(`⚠️ ${error}.`)
      }
      notification(`🎉 You successfully added "${params[0]}".`)
      getProducts()
    })

  function renderProducts() {
    document.getElementById("marketplace").innerHTML = ""
    products.forEach((_product) => {
      const newDiv = document.createElement("div")
      newDiv.className = "col-md-4"
      newDiv.innerHTML = productTemplate(_product)
      document.getElementById("marketplace").appendChild(newDiv)
    })
  }

  function productTemplate(_product) {
    return `
      <div class="card mb-4">
        <img class="card-img-top" src="${_product.image}" alt="...">
        <div class="position-absolute top-0 end-0 bg-warning mt-4 px-2 py-1 rounded-start">
          ${_product.sold} Sold
        </div>
        <div class="card-body text-left p-4 position-relative">
          <div class="translate-middle-y position-absolute top-0">
          ${identiconTemplate(_product.owner)}
          </div>
          <h2 class="card-title fs-4 fw-bold mt-2">${_product.name}</h2>
          <p class="card-text mb-4" style="min-height: 82px">
            ${_product.description}             
          </p>
          <p class="card-text mt-4">
            <i class="bi bi-geo-alt-fill"></i>
            <span>${_product.location}</span>
          </p>
          <div class="d-grid gap-2">
            <a class="btn btn-lg btn-outline-dark buyBtn fs-6 p-3" id=${
              _product.index
            }>
              Buy for ${_product.price.shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
            </a>
          </div>
        </div>
      </div>
    `
  }
  window.addEventListener('load', async () => {
    notification("⌛ Loading...")
    await connectCeloWallet()
    await getBalance()
    await getProducts()
    notificationOff()
  });

function identiconTemplate(_address) {
    const icon = blockies
      .create({
        seed: _address,
        size: 8,
        scale: 16,
      })
      .toDataURL()
  
    return `
    <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
      <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
          target="_blank">
          <img src="${icon}" width="48" alt="${_address}">
      </a>
    </div>
    `
  }

  function notification(_text) {
    document.querySelector(".alert").style.display = "block"
    document.querySelector("#notification").textContent = _text
  }
  
  function notificationOff() {
    document.querySelector(".alert").style.display = "none"
  }

  window.addEventListener("load", () => {
    notification("⌛ Loading...")
    getBalance()
    renderProducts()
    notificationOff()
  })

  document
  .querySelector("#newProductBtn")
  .addEventListener("click", () => {
    const _product = {
      owner: "0x2EF48F32eB0AEB90778A2170a0558A941b72BFFb",
      name: document.getElementById("newProductName").value,
      image: document.getElementById("newImgUrl").value,
      description: document.getElementById("newProductDescription").value,
      location: document.getElementById("newVenue").value,
      price: document.getElementById("newPrice").value,
      sold: 0,
      index: products.length ||0,
    }
    products.push(_product)
    notification(`🎉 You successfully added "${_product.name}".`)
    renderProducts()
  })

  document.querySelector("#marketplace").addEventListener("click", (e) => {
    if(e.target.className.includes("buyBtn")) {
      const index = e.target.id
      products[index].sold++
      notification(`🎉 You successfully bought "${products[index].name}".`)
      renderProducts()
    }
  })