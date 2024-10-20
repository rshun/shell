# install bakstock
pip3 install baostock -i https://pypi.org/simple 
if [ $? -eq 1 ]
then
    echo "install error"
    exit -1
fi

echo "
import baostock as bs
import pandas as pd

#### 登陆系统 ####
lg = bs.login()

#### 获取沪深A股历史K线数据 ####
# 详细指标参数，参见“历史行情指标参数”章节；“分钟线”参数与“日线”参数不同。“分钟线”不包含指数。
# 分钟线指标：date,time,code,open,high,low,close,volume,amount,adjustflag
# 周月线指标：date,code,open,high,low,close,volume,amount,adjustflag,turn,pctChg
rs = bs.query_history_k_data_plus("sh.600000",
    "date,code,open,high,low,close,preclose,volume,amount,adjustflag,turn,tradestatus,pctChg,isST",
    start_date='2024-07-01', end_date='2024-07-31',
    frequency="d", adjustflag="3")
print('query_history_k_data_plus respond error_code:'+rs.error_code)
print('query_history_k_data_plus respond  error_msg:'+rs.error_msg)

#### 打印结果集 ####
data_list = []
while (rs.error_code == '0') & rs.next():
    # 获取一条记录，将记录合并在一起
    data_list.append(rs.get_row_data())
result = pd.DataFrame(data_list, columns=rs.fields)

print(result)
bs.logout()
" >$HOME/src/py/helloworld_baostock.py

echo "now run baostock"
python3 $HOME/src/py/helloworld_baostock.py

# install akshare
pip3 install akshare --upgrade
if [ $? -eq 1 ]
then
    echo "install error"
    exit -1
fi

echo "
import akshare as ak

stock_sse_summary_df = ak.stock_sse_summary()
print(stock_sse_summary_df)
">$HOME/src/py/helloworld_akshare.py

echo "now run akshare"
python3 $HOME/src/py/helloworld_baostock.py