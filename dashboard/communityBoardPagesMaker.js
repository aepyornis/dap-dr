const fs = require('fs');
const path = require('path');
const pug = require('pug');

const mapValues = require('lodash/mapValues');
const groupBy = require('lodash/groupBy');
const toPairs = require('lodash/toPairs');
const merge = require('lodash/merge');
const round = require('lodash/round');
const isUndefined = require('lodash/isUndefined');

const format = require('d3-format').format;
const toN = require('./toN');

// commmunity board data
const communityBoardsData = require('./community_boards.json');

const saveFile = (fileName, html, folder) => {
  fs.writeFileSync(`${folder}/${fileName}.html`, html);
};

/**
 * Formats and generates stats values for the template
 * @param {Object} stats
 * @returns {Ojbect} stats
 */
const statsPresenter = (stats) => {
  let numericStats = mapValues(stats, toN);
  let formattedStats = {
    "openViolationsPerUnit": round( numericStats.openViolationsPerUnit,  2).toString() ,
    "resBuildingsWithViolationsPct": format(".1%")( ( numericStats.buildingsWithOpenViolations / numericStats.buildingsres) )
  };
  
  let statsWithComma = mapValues(stats, stat => format(',')(toN(stat)));
  return merge(statsWithComma, formattedStats);
};

//compiled pug templates
const communityBoardTemplate = pug.compileFile(path.join(__dirname, 'templates', 'communityBoard.pug'), {});
const indexTemplate = pug.compileFile(path.join(__dirname, 'templates', 'index.pug'));


const index = (folder) => {
  // data structure: [ 'Bronx'. [ {}, {} ] ]
  let districtData = { districts: toPairs(groupBy(communityBoardsData, 'borough')) };
  let html = indexTemplate(districtData);
  saveFile('index', html, folder);
};

/**
 * 
 * @param {Objects} communityBoardsJson 
 * @param {Object} - bbl count lookup thingy
 */
const bblCount = (communityBoard) => {
  let bbls = {};
  const datasets = [ 'recentSales', 'hpdViolations', 'dobjobs', 'dobComplaints', 'hpdComplaints' ];
  datasets.forEach(ds => {
    communityBoard[ds].forEach( taxLot => {
      if (isUndefined(bbls[taxLot.bbl])) {
        bbls[taxLot.bbl] = [ ds ];
      } else {
        bbls[taxLot.bbl] = bbls[taxLot.bbl].concat([ ds ]);
      }
    });
  })
  return bbls;
}

const rowClassFun = () => {
  const classLookup = { 
    1: 'f6',
    2: 'f6 dapyellow', 
    3: 'f6 daporange', 
    4: 'f6 dapred', 
    5: 'f6 dapred'
  };
  return (count) => classLookup[count];
}

/**
 * Turn an array of information about community boards into html 
 * and saves them
 * @param {Array[Objects]} communityBoardsJson
 * @param {String]} outputFolder
 */
const main = (communityBoardsJson, folder) => {
  index(folder);

  communityBoardsJson
    .map( board => merge(board, {stats: statsPresenter(board.stats) }) )
    .map( board => merge(board, {bblCount: bblCount(board), rowClass: rowClassFun() }))
    .map( board => ( { fileName: board.district.cd, html: communityBoardTemplate(board) } ) )
    .forEach( ({fileName, html}) => saveFile(fileName, html, folder) );
};

main._statsPresenter = statsPresenter;

module.exports = main;
