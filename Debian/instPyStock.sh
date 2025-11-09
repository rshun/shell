#!/bin/bash
VENV_DIRPATH=$HOME/src/venv

installvenv()
{
if [ ! -d $VENV_DIRPATH ];
then
    mkdir -p $VENV_DIRPATH
fi 

cd $VENV_DIRPATH
python3 -m venv stock
source stock/bin/activate
pip3 install baostock -i https://pypi.org/simple 
pip3 install akshare --upgrade
deactivate
}

bakstock_demo()
{
echo "
import baostock as bs
import pandas as pd

#### 登陆系统 ####
lg = bs.login()

#### 获取沪深A股历史K线数据 ####
rs = bs.query_history_k_data_plus(\"sh.600036\",
    \"date,code,open,high,low,close,preclose,volume,amount,adjustflag,turn,tradestatus,pctChg,isST\",
    start_date=\"2024-07-01\", end_date=\"2024-07-31\",
    frequency=\"d\", adjustflag=\"3\")

data_list = []
while (rs.error_code == \"0\") & rs.next():
    data_list.append(rs.get_row_data())
result = pd.DataFrame(data_list, columns=rs.fields)

print(result)
bs.logout()
" >$HOME/src/py/helloworld_baostock.py
}


akshare_demo()
{

echo "
import akshare as ak

begin_date=\"20251001\"
end_date=\"20251031\"
stock_list = ak.stock_zh_a_hist(symbol=\"600036\", period=\"daily\", start_date=begin_date, end_date=end_date, adjust=\"\",timeout=5)
print(stock_list)

">$HOME/src/py/helloworld_akshare.py
}

rundemo()
{
cd $VENV_DIRPATH
echo "now run baostock"

python3 -m venv stock
source stock/bin/activate
python3 $HOME/src/py/helloworld_baostock.py


echo "now run akshare"
python3 $HOME/src/py/helloworld_akshare.py

deactivate
}

installvenv
bakstock_demo
akshare_demo
rundemo
echo "install pystock is finished...."


