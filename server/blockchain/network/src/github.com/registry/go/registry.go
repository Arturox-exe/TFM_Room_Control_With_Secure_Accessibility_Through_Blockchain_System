package main

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/golang/protobuf/ptypes"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SimpleChaincode implements the fabric-contract-api-go programming model
type SimpleChaincode struct {
	contractapi.Contract
}

type Registry struct {
	DocType string `json:"docType"`
	ID      string `json:"id"`
	Date    string `json:"date"`
	Quarantine string `json:"quarantine"`
	Visitor    Visitor   `json:"visitor"`
	Patient    Patient   `json:"patient"`
}

type Visitor struct {
	DocType string `json:"docType"`
	IdVisitor  string `json:"idVisitor"`
}

type Patient struct {
	DocType string `json:"docType"`
	IdPatient  string `json:"idPatient"`
	Illness string `json:"illness"`
}

// PaginatedQueryResult structure used for returning paginated query results and metadata
type PaginatedQueryResult struct {
	Records             []*Registry `json:"records"`
	FetchedRecordsCount int32       `json:"fetchedRecordsCount"`
	Bookmark            string      `json:"bookmark"`
}

// HistoryQueryResult structure used for returning result of history query
type HistoryQueryResultC struct {
	Record    *Registry `json:"record"`
	TxId      string    `json:"txId"`
	Timestamp time.Time `json:"timestamp"`
	IsDelete  bool      `json:"isDelete"`
}

// CreateRegistry initializes a new asset in the ledger
func (t *SimpleChaincode) CreateRegistry(ctx contractapi.TransactionContextInterface, id string, date string, idvisitor string, idpatient string, illness string) error {

	exists, err := t.AssetExists(ctx, id)
	if err != nil{
		return err
	}

	assetVisitor := Visitor{
		DocType: "visitor",
		IdVisitor:  idvisitor,
	}	


	assetPatient := Patient{
		DocType: "patient",
		IdPatient:  idpatient,
		Illness: illness,
	}
	
	if exists == nil{
		assetData := Registry{
			DocType: "registry",
			ID:      id,
			Date:    date,
			Quarantine: "No",
			Visitor:    assetVisitor,
			Patient: assetPatient,
		}

		assetBytes, err := json.Marshal(assetData)

		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(id, assetBytes)

		if err != nil {
			return err
		}

		return ctx.GetStub().PutState(id, assetBytes)
	} else {
		assetData := Registry{
			DocType: "registry",
			ID:      id,
			Date:    date,
			Quarantine: exists.Quarantine,
			Visitor:    assetVisitor,
			Patient: assetPatient,

		}

		assetBytes, err := json.Marshal(assetData)

		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(id, assetBytes)

		if err != nil {
			return err
		}

		return ctx.GetStub().PutState(id, assetBytes)
	}
	

	
}

func (t *SimpleChaincode) ChangeQuarantine(ctx contractapi.TransactionContextInterface, id string, quarantine string, date string) error {

	readasset, err := t.ReadRegistry(ctx, id)
	if err != nil{
		return err
	}

	if quarantine == readasset.Quarantine {
		return nil
	}

	readasset.Quarantine = quarantine

	readasset.Date = date

	readasset.Visitor.IdVisitor = ""

	assetBytes, err := json.Marshal(readasset)

	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, assetBytes)

	
}

// ReadAsset retrieves an asset from the ledger
func (t *SimpleChaincode) AssetExists(ctx contractapi.TransactionContextInterface, assetID string) (*Registry, error) {
	assetBytes, err := ctx.GetStub().GetState(assetID)
	if err != nil {
		return nil, fmt.Errorf("error checking the registry %s: %v", assetID, err)
	}
	if assetBytes == nil {
		return nil, nil
	}

	var asset Registry

	err = json.Unmarshal(assetBytes, &asset)
	if err != nil {
		return nil, err
	}

	return &asset, nil
}



// ReadAsset retrieves an asset from the ledger
func (t *SimpleChaincode) ReadRegistry(ctx contractapi.TransactionContextInterface, assetID string) (*Registry, error) {
	assetBytes, err := ctx.GetStub().GetState(assetID)
	if err != nil {
		return nil, fmt.Errorf("error checking the registry %s: %v", assetID, err)
	}
	if assetBytes == nil {
		return nil, fmt.Errorf("the registry do not exists")
	}

	var asset Registry

	err = json.Unmarshal(assetBytes, &asset)
	if err != nil {
		return nil, err
	}

	return &asset, nil
}

func (t *SimpleChaincode) GetAssetHistory(ctx contractapi.TransactionContextInterface, assetID string) ([]HistoryQueryResultC, error) {

	resultsIterator, err := ctx.GetStub().GetHistoryForKey(assetID)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var records []HistoryQueryResultC
	for resultsIterator.HasNext() {
		response, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var asset Registry
		if len(response.Value) > 0 {
			err = json.Unmarshal(response.Value, &asset)
			if err != nil {
				return nil, err
			}
		} else {
			asset = Registry{
				ID: assetID,
			}
		}

		timestamp, err := ptypes.Timestamp(response.Timestamp)
		if err != nil {
			return nil, err
		}

		record := HistoryQueryResultC{
			TxId:      response.TxId,
			Timestamp: timestamp,
			Record:    &asset,
			IsDelete:  response.IsDelete,
		}
		records = append(records, record)
	}

	return records, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SimpleChaincode{})
	if err != nil {
		log.Panicf("Error creating the chaincode: %v", err)
	}

	if err := chaincode.Start(); err != nil {
		log.Panicf("Error pulling the chaincode: %v", err)
	}
}
