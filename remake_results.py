import os
from glob import glob
import pandas as pd
import sys

if len(sys.argv) == 3:
    PATH = sys.argv[1]
    result_name = sys.argv[2]
elif len(sys.argv) == 2:
    PATH = sys.argv[1]
    result_name = 'targetscan_70_context_scores_output.txt'
else:
    PATH = 'tmp'
    result_name = 'targetscan_70_context_scores_output.txt'

df = pd.DataFrame({})

for path in os.listdir(PATH):
    print('processing', path)
    tmp = pd.read_csv(os.path.join(PATH, path, result_name),
                      sep='\t', index_col=0)
    df = pd.concat([df, tmp])
df = df.copy()
print(df)
print(df.index.unique())
