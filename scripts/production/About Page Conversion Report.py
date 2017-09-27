from __future__ import division
import vertica_python
import numpy as np
from pandas import Series, DataFrame
import pandas as pd
from vertica_python import connect
import StringIO
from StringIO import StringIO
from datetime import date, timedelta as td
import xlsxwriter
import os
import json
import urllib2
import base64
import datetime
import re
import csv


# Date Parameters Here
#d1 = date(2016, 10, 21) # Start Date
d1=(date.today()+datetime.timedelta(days=-8))
d2=(date.today()+datetime.timedelta(days=-1))

import argparse

from apiclient.discovery import build
import httplib2
from oauth2client import client
from oauth2client import file
from oauth2client import tools


def get_service(api_name, api_version, scope, client_secrets_path):
  """Get a service that communicates to a Google API.

  Args:
    api_name: string The name of the api to connect to.
    api_version: string The api version to connect to.
    scope: A list of strings representing the auth scopes to authorize for the
      connection.
    client_secrets_path: string A path to a valid client secrets file.

  Returns:
    A service that is connected to the specified API.
  """
  # Parse command-line arguments.
  parser = argparse.ArgumentParser(
      formatter_class=argparse.RawDescriptionHelpFormatter,
      parents=[tools.argparser])
  flags = parser.parse_args([])

  # Set up a Flow object to be used if we need to authenticate.
  flow = client.flow_from_clientsecrets(
      client_secrets_path, scope=scope,
      message=tools.message_if_missing(client_secrets_path))

  # Prepare credentials, and authorize HTTP object with them.
  # If the credentials don't exist or are invalid run through the native client
  # flow. The Storage object will ensure that if successful the good
  # credentials will get written back to a file.
  storage = file.Storage(api_name + '.dat')
  credentials = storage.get()
  if credentials is None or credentials.invalid:
    credentials = tools.run_flow(flow, storage, flags)
  http = credentials.authorize(http=httplib2.Http())

  # Build the service object.
  service = build(api_name, api_version, http=http)

  return service

# Gets rid of | edx from GA Page_Title
def substring(x):
    z=len(x)
    y=(z-6)
    temp=x[:y]
    return temp.strip()
x = substring('IELTS Academic Test Preparation                 | edX')


# Get course enrollents from GA event firing
def get_courseEnrolls(service,date):
  # Use the Analytics Service Object to query the Core Reporting API
  # for the number of sessions in the past seven days.
  return service.data().ga().get(
      ids='ga:' + '86300562',
      start_date=str(date),
      end_date=str(date),
      max_results=10000,
      metrics='ga:totalEvents,ga:uniqueEvents',
      dimensions='ga:date,ga:pageTitle,ga:eventLabel',
      filters='ga:eventAction==edx.bi.user.course-details.enroll.header,ga:eventAction==edx.bi.user.course-details.enroll.main,ga:eventAction==edx.bi.user.xseries-details.enroll.discovery-card').execute()

# Get About Page Views
def get_courseViews(service,date):
  # Use the Analytics Service Object to query the Core Reporting API
  # for the number of sessions in the past seven days.
  return service.data().ga().get(
      ids='ga:' + '86300562',
      start_date=str(date),
      end_date=str(date),
      max_results=10000,
      metrics='ga:pageviews,ga:uniquePageviews,ga:exits,ga:entrances,ga:bounces',
      dimensions='ga:date,ga:pageTitle',
      filters='ga:pagePath!~^/course/subject/;ga:pageTitle!=Courses | edX;ga:pagePath=~^/course/,ga:pagePath=~^/xseries/').execute()

# Get registrations from GA event firing
def get_courseRegistrations(service,date):
  # Use the Analytics Service Object to query the Core Reporting API
  # for the number of sessions in the past seven days.
  return service.data().ga().get(
      ids='ga:' + '86300562',
      start_date=str(date),
      end_date=str(date),
      max_results=10000,
      metrics='ga:totalEvents,ga:uniqueEvents',
      dimensions='ga:date,ga:pageTitle,ga:eventLabel',
      filters='ga:eventAction==edx.bi.user.account.registered').execute()


# Define the auth scopes to request.
scope = ['https://www.googleapis.com/auth/analytics.readonly']

# Authenticate and construct service.
service = get_service('analytics', 'v3', scope, 'client_secrets.json')

delta = d2 - d1

t=0

# Pull data daily and then consolidate
for i in range(delta.days + 1):
    t=t+1
    dt=d1 + td(days=i)
    strDt=str(dt)
    print dt
    print t
    if t==1:
        enData=get_courseEnrolls(service,strDt)['rows']
        pvData=get_courseViews(service,strDt)['rows']
        rnData=get_courseRegistrations(service,strDt)['rows']

        
    if t>1:
        enData=enData+get_courseEnrolls(service,strDt)['rows']
        pvData=pvData+get_courseViews(service,strDt)['rows']
        rnData=rnData+get_courseRegistrations(service,strDt)['rows']


# Get Course Metadata from Vertica here
# Set up Vertica Connection Information
conn_info = {'host' : 'warehouse.analytics.edx.org',
             'port' : 5433,
             'user' : 'ojchang',
             'password' : 'Lej@mes8',
             'database' : 'warehouse'
            }

connection = vertica_python.connect(**conn_info)
cur = connection.cursor('dict')

cur.execute("""

select 
  course_id as event_label,
  date(start_time) as start_date,
  date(end_time) as end_date,
  pacing_type,
  org_id
from
  production.d_course;


""")

courseorgdata = pd.DataFrame(cur.fetchall())
courseorgdata


# Get Total Course Enrollments, Verifications, and VTR from Vertica
# Set up Vertica Connection Information
conn_info = {'host' : 'warehouse.analytics.edx.org',
             'port' : 5433,
             'user' : 'ojchang',
             'password' : 'Lej@mes8',
             'database' : 'warehouse'
            }

connection = vertica_python.connect(**conn_info)
cur = connection.cursor('dict')

cur.execute("""

select 
  a.course_id as event_label,
  sum(case when first_enrollment_time <= course_seat_upgrade_deadline then 1 else 0 end) as Enrollments,
  count(first_verified_enrollment_time) as Verifications,
  (count(first_verified_enrollment_time)/sum(case when first_enrollment_time <= course_seat_upgrade_deadline then 1 else 0 end)) as VTR
from
  production.d_user_course a
left join
  ed_services.UpgradeDeadlineCourses b on a.course_id = b.course_id
where 
  course_seat_upgrade_deadline is not null
group by
  a.course_id
having sum(case when first_enrollment_time <= course_seat_upgrade_deadline then 1 else 0 end) > 0
union
select
  a.course_id as event_label,
  count(*) as Enrollments,
  count(first_verified_enrollment_time) as Verifications,
  count(first_verified_enrollment_time)/count(*) as VTR
from
  production.d_user_course a
left join
  ed_services.UpgradeDeadlineCourses b on a.course_id = b.course_id
where
  course_seat_upgrade_deadline is null
group by
  a.course_id


""")

courseenrollverifdata = pd.DataFrame(cur.fetchall())
courseenrollverifdata        



# Join all data together
hpViewData=DataFrame(pvData,columns=['date','page_title','aboutViews','uniqueAboutViews','exits','entrances','bounces'])
hpViewData=hpViewData.convert_objects(convert_numeric=True)
hpViewData.drop('date', axis=1, inplace=True)
hpViewData['courseName']=hpViewData['page_title'].apply(lambda x: substring(x))
hpViewDataAgg=hpViewData.groupby(['courseName']).sum().sort(['uniqueAboutViews'],ascending=0)
hpViewDataAgg.reset_index(inplace=True)
#hpViewDataAgg.head() 


hpEnrollData=DataFrame(enData,columns=['date','page_title','event_label','totalEnrolls','uniqueEnrolls'])
hpEnrollData=hpEnrollData.convert_objects(convert_numeric=True)
hpEnrollData.drop('date', axis=1, inplace=True)
hpEnrollData['courseName']=hpEnrollData['page_title'].apply(lambda x: substring(x))
hpEnrollDataAgg=hpEnrollData.groupby(['courseName','event_label']).sum().sort(['uniqueEnrolls'],ascending=0)
hpEnrollDataAgg.reset_index(inplace=True)
hpEnrollDataAgg.to_clipboard(excel=True,encoding='utf-8')
#hpEnrollDataAgg.head()


hpRegData=DataFrame(rnData,columns=['date','page_title','event_label','totalRegistrations','uniqueRegistrations'])
hpRegData=hpRegData.convert_objects(convert_numeric=True)
hpRegData.drop('date', axis=1, inplace=True)
hpRegData['courseName']=hpRegData['page_title'].apply(lambda x: substring(x))
hpRegDataAgg=hpRegData.groupby(['courseName','event_label']).sum().sort(['uniqueRegistrations'],ascending=0)
hpRegDataAgg.reset_index(inplace=True)
hpRegDataAgg.to_clipboard(excel=True,encoding='utf-8')
#hpRegDataAgg.head()


crData=pd.merge(hpViewDataAgg,hpEnrollDataAgg,on='courseName',how='left')
crData['CR'] =(crData['uniqueEnrolls'] /crData['uniqueAboutViews'])
crData['bounceRate'] =(crData['bounces'] /crData['entrances'])
prefinalData=crData[['courseName','event_label','aboutViews','uniqueAboutViews','uniqueEnrolls','entrances','CR','bounceRate']]
prefinalData=prefinalData[(prefinalData['courseName'].str.lower().str.contains('demox')==False)]
p=prefinalData['aboutViews'].quantile(.45)
cr75=prefinalData['CR'].quantile(.75)
br25=prefinalData['bounceRate'].quantile(.8)
prefinalData=prefinalData[(prefinalData['aboutViews']>=p)]
print cr75, br25
#prefinalData


finalData=pd.merge(prefinalData,hpRegDataAgg,on='event_label',how='left')
finalData.drop('courseName_y',axis=1,inplace=True)
#finalData


# Merge Course Metadata
FcData = pd.merge(finalData, courseorgdata, on='event_label', how='left')
FcData['courseName']=FcData['courseName_x']
FcData = FcData[['pacing_type', 'courseName', 'org_id', 'event_label', 'start_date', 'end_date', 'aboutViews', 'uniqueAboutViews', 'uniqueEnrolls', 'uniqueRegistrations', 'CR', 'entrances', 'bounceRate']]
#FcData


# Final Data Join Here
FData = pd.merge(FcData, courseenrollverifdata, on='event_label', how='left')
FData = FData[['pacing_type', 'courseName', 'org_id', 'event_label', 'start_date', 'end_date', 'aboutViews', 'uniqueAboutViews', 'uniqueEnrolls', 'uniqueRegistrations', 'CR', 'Enrollments', 'Verifications', 'VTR', 'entrances', 'bounceRate']]
#FData


# Create Excel File and Report
filepath = "C:/Users/ochang/Desktop/Weekly Marketing Reports/About Page Conversion Reports/"
excelFile=str(filepath)+'About Page Data '+str(d1)+' to '+str(d2)+'.xlsx'
from pandas import ExcelWriter
writer = pd.ExcelWriter(excelFile,engine='xlsxwriter')
FData.to_excel(writer, index=False, sheet_name='AboutPagePerformance', startrow=2)


# Get access to the workbook and sheet
workbook = writer.book
worksheet = writer.sheets['AboutPagePerformance']

money_fmt = workbook.add_format({'num_format': '$#,##0', 'bold': True})
percent_fmt = workbook.add_format({'num_format': '0.0%', 'bold': False})
comma_fmt = workbook.add_format({'num_format': '#,##0', 'bold': False})
date_fmt = workbook.add_format({'num_format': 'dd/mm/yy'})
cell_format = workbook.add_format({'bold': True, 'italic': False})

worksheet.conditional_format('P1:P10000', {'type':'2_color_scale','min_color': '#C5D9F1','max_color': '#538ED5'})
worksheet.conditional_format('N1:N10000', {'type': '3_color_scale'})
worksheet.conditional_format('K1:K10000', {'type': '3_color_scale'})


worksheet.set_column('A:A', 22)
worksheet.set_column('B:B', 70)
worksheet.set_column('C:C', 20)
worksheet.set_column('D:D', 30)
worksheet.set_column('E:F', 25, date_fmt)
worksheet.set_column('G:J', 22, comma_fmt)
worksheet.set_column('L:M', 22, comma_fmt)
worksheet.set_column('O:O', 22, comma_fmt)
worksheet.set_column('N:N', 15, percent_fmt)
worksheet.set_column('K:K', 15, percent_fmt)
worksheet.set_column('P:P', 15, percent_fmt)


worksheet.write('A1', 'About Page Performance, Data from '+str(d1)+' to '+str(d2) , cell_format)

worksheet.autofilter('A3:N3')

worksheet.freeze_panes(3, 4)

writer.save()
