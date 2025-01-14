//MI AMOR TE AMO CON TODA MI ALMA, I LOVE UUUUUUUUU

#include <Trade/Trade.mqh>

CTrade trade;

input ENUM_TIMEFRAMES timeframe = PERIOD_M5;
int barsTotal;
input double lots = 1.1;
double accountBalance;
double middelBandArray[], upperBandArray[], lowBandArray[];
double middelBandValue, upperBandValue, lowBandValue;
int Rsi;
double RSI[], RSIvalue;
double ask, bid;
double actualPrice;
int bollingerBans, ema;
double TpFactor = 3.33;
int stoch;
double KArray[], DArray[];
double KAvalue0, DAvalue0, KAvalue1, DAvalue1;

int OnInit() {
    accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);

    barsTotal=iBars(_Symbol,timeframe);
    bollingerBans = iBands(_Symbol, timeframe, 20, 0, 2, PRICE_CLOSE);
    ema = iMA(_Symbol, timeframe, 14, 0, MODE_EMA, PRICE_CLOSE);
    Rsi = iRSI(_Symbol, timeframe, 14, PRICE_CLOSE);
    stoch = iStochastic(_Symbol, timeframe, 6, 3, 3, MODE_SMA, STO_LOWHIGH);

    ArrayResize(middelBandArray, 3);
    ArrayResize(upperBandArray, 3);
    ArrayResize(lowBandArray, 3);
    ArrayResize(KArray, 3); // Resize the arrays for Stochastic
    ArrayResize(DArray, 3);

    if (stoch == INVALID_HANDLE) {
        Print("Failed to create Stochastic handle");
        return INIT_FAILED;
    }

    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
}

void OnTick() {

    /*
    double balance=GetAccountBalance();
    Comment("Account Balance: ", balance);
    */
    // Ensure arrays are set as series
    ArraySetAsSeries(KArray, true);
    ArraySetAsSeries(DArray, true);

    // Copy the stochastic indicator values
    int copiedK = CopyBuffer(stoch, 0, 0, 3, KArray);
    int copiedD = CopyBuffer(stoch, 1, 0, 3, DArray);

    if (copiedK <= 0 || copiedD <= 0) {
        Print("Failed to get Stochastic data. copiedK: ", copiedK, ", copiedD: ", copiedD);
        return;
    }
    
    //D% es el rojo
    //k% es el azul
    //si el rojo es mayor que el azul vendemos= si D%>K% buying
    //si azul mayor que rojo, compramos= si K%>D% selling

    KAvalue0 = NormalizeDouble(KArray[0], _Digits);
    DAvalue0 = NormalizeDouble(DArray[0], _Digits);
    KAvalue1 = NormalizeDouble(KArray[1], _Digits);
    DAvalue1 = NormalizeDouble(DArray[1], _Digits);

    // Copy RSI values
    ArraySetAsSeries(RSI, true);
    int copiedRSI = CopyBuffer(Rsi, 0, 0, 3, RSI);
    if (copiedRSI <= 0) {
        Print("Failed to get RSI data. copiedRSI: ", copiedRSI);
        return;
    }
    RSIvalue = NormalizeDouble(RSI[0], _Digits);
    
    ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    actualPrice = iClose(_Symbol, timeframe, 0);

    // Ensure arrays are set as series
    ArraySetAsSeries(middelBandArray, true);
    ArraySetAsSeries(upperBandArray, true);
    ArraySetAsSeries(lowBandArray, true);

    if (CopyBuffer(bollingerBans, 0, 0, 3, middelBandArray) <= 0 ||
        CopyBuffer(bollingerBans, 1, 0, 3, upperBandArray) <= 0 ||
        CopyBuffer(bollingerBans, 2, 0, 3, lowBandArray) <= 0) {
        Print("Failed to get Bollinger Bands data");
        return;
    }

    middelBandValue = NormalizeDouble(middelBandArray[0], _Digits);
    upperBandValue = NormalizeDouble(upperBandArray[0], _Digits);
    lowBandValue = NormalizeDouble(lowBandArray[0], _Digits);

    // Check for open trades to avoid multiple positions
    if (PositionsTotal() == 0) {
        if (KAvalue0 > 80 && DAvalue0 > 80 && DAvalue1>KAvalue1 && RSIvalue > 70 && bid > upperBandValue) {
            double sl = bid + 0.00025;
            double tp = bid-0.0005;
            bool result = trade.Sell(lots, _Symbol, bid, sl, tp);
            if (result) {
                Print("sell order executed successfully");
            } else {
                int error = GetLastError();
                Print("Error executing buy order: ", error);
                ResetLastError();
            }
        }
        if (KAvalue0 < 20 && DAvalue0 < 20  && KAvalue1>DAvalue1 && RSIvalue <30  && ask < lowBandValue) {
            double sl = ask - 0.00025;
            double tp = ask+0.0005;;
            bool result = trade.Buy(lots, _Symbol, ask, sl, tp);
            if (result) {
                Print("buy order executed successfully");
            } else {
                int error = GetLastError();
                Print("Error executing sell order: ", error);
                ResetLastError();
            }
        }
    }
    
    //STRATEGY SECOND
    int bars=iBars(_Symbol,timeframe); 
    
    if(barsTotal != bars){
    barsTotal=bars;
    
    //this is how to draw patterns of bars
    double open1=iOpen(_Symbol,timeframe,1);
    double close1=iClose(_Symbol,timeframe,1);
    
    double open2=iOpen(_Symbol,timeframe,2);
    double close2=iClose(_Symbol,timeframe,2);
    
    double open3=iOpen(_Symbol,timeframe,3);
    double close3=iClose(_Symbol,timeframe,3);
    
    double open4=iOpen(_Symbol,timeframe,4);
    double close4=iClose(_Symbol,timeframe,4);
    
    if(open1 <close1){ //checking if the last bar is green
      if(open2 > close2 && open3 >close3 && open4 > close4){ //red
        if(close1 >open4){ //check if last bar is really big
          Print("buy signal...");
          double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
          //get lowest low of the last 4 bars
          int indexLowestLow=iLowest(_Symbol,timeframe,MODE_LOW,4,1);
          //get low of the lowest low of the last 4 bars
          double sl=ask-0.00033;
          double tp=ask+0.00025;
          trade.Buy(lots,_Symbol,ask,sl,tp);
        }
      }
    }
    
    if(open1 > close1){  //checking if the last bar is red
      if(open2<close2 && open3<close3 && open4<close4){ //green
        if(close1 < open4){ //check if last bar is really big
          Print("sell signal...");
          double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
          //get highest hiw of the last 4 bars
          int indexHighestHigh=iHighest(_Symbol,timeframe,MODE_LOW,4,1);
          //get low of the lowest low of the last 4 bars
          double sl=bid+0.00033;
          double tp=bid-0.00015;
          trade.Sell(lots,_Symbol,bid,sl,tp);
        }
      }
    }
  }
  
  //STRATEGY THREE
  //NI LO TOQUES, ESTÁ MAS QUE PERFECTO
    if(RSIvalue>75){
      if(KAvalue0>80 && DAvalue0>80){
        double sl = bid + 0.0007;
        double tp = bid-0.0006;
        bool result = trade.Sell(lots, _Symbol, bid, sl, tp);
        if (result) {
          Print("sell order executed successfully");
        } else {
          int error = GetLastError();
          Print("Error executing buy order: ", error);
          ResetLastError();
        }
      }
    }
}

// Función para obtener el saldo de la cuenta
/*
double GetAccountBalance() {
    return AccountInfoDouble(ACCOUNT_BALANCE);
}
*/
