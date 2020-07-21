"""
Author: Colin Fritz 
Date: 06/30/2020
Purpose:  Tool for pulling Github Pull Request data from a repo into a searchable
text file.  Useful for having a local record of conversations between reviewers and 
authors in the D0-254 documentation workflow.  
"""


from github import Github #API used to simplify using the Github API 
import textwrap 
import sys 


def print_header(repo_object):
	"""
	function: prints header of file
	"""
	print('project_name: ' + repo_object.name)
	print(' ')

def print_author(pull_req_object):
	"""
	function: prints author of the pull request
	"""
	print('Author: ' + pull_req_object.user.login)

def print_top_border(pull_req_object):
	"""
	function: prints the title of the pull request
	"""
	print('------------------------- ' + pull_req_object.title + '------------------------- ')

def print_reviewers(pull_req_object):
	"""
	function: prints reviewers in formatting one line 
	"""
	reviewers= []
	for reviewer in pull_req_object.get_reviews():
		reviewers.append(reviewer.user.login)
	reviewers = set(reviewers)
	print('Reviewers:', *reviewers)

def print_ID(pull_req_object):
	"""
	function: print ID of pull request
	"""
	print('ID: ' + str(pull_req_object.id))

def print_created(pull_req_object):
	"""
	function: prints the created time of the pull request 
	"""
	print('Created: ' + str(pull_req_object.created_at))

def print_closed(pull_req_object):
	"""
	function: prints the closed time of the pull request 
	"""
	print('Closed: ' + str(pull_req_object.closed_at))

def print_description(pull_req_object):
	"""
	function: prints the description included in the pull request opening 
	"""
	print('Description: ' + pull_req_object.body)
	print(' ')

def print_review_comments(pull_req_object):
	"""
	function: prints review comments under the review comments header.  
	review comments are grouped underneath the related review body.  
	"""
	
	print('Review Comments: ')
	for review_comment in pull_req_object.get_reviews():
		print(review_comment.user.login + ' ' + str(review_comment.submitted_at))
		comment=textwrap.fill(review_comment.body, width=50)
		comment.encode('unicode_escape')
		print("Body: " + comment)
		for line_comm in pull_req_object.get_single_review_comments(review_comment.id):
				print(line_comm.user.login + ' ' + str(line_comm.position) + ' ' + line_comm.path)
				print(textwrap.fill(line_comm.body, width=50))
		
		print(' ')

def print_conversational_comments(pull_req_object):
	"""
	function: prints conversational comments header.  Beneath this header 
	conversational comments are printed in chronological order with timestamps.  
	"""
	print('Conversational Comments: ')
	for conversational_comment in pull_req_object.get_issue_comments():
		print(conversational_comment.user.login + ' ' + str(conversational_comment.created_at))
		print(textwrap.fill(conversational_comment.body, 50))
		print(' ')
	print(' ')

def print_bottom_border(pull_req_object):
	"""
	function: prints bottom border to demark the end of a pull request data area
	"""
	print('------------------------- ' + pull_req_object.title + '------------------------- ')
	print('')
	print('')
	print('')

def print_merge_commit_sha(pull_req_object):
	"""
	function: prints the sha of the merge commit added to branch being merged into.  May or not actually exist.  
	depends on if pull request has been approved and merged or not.  
	"""
	print('merge_commit_sha: ' + pull_req_object.merge_commit_sha)

def print_changed_files(pull_req_object):
	"""
	function: prints out the files under review in the pull request 
	"""
	print('Changed_Files: ')
	for file in pull_req_object.get_files():
		print("file1: " + file.filename)


"""
Defining which repo to pull data from.  
"""
filename = '/Users/colinfritz/my_repos/CAN_Controller/Review_History' # Location for exporting Pull Request info
account_username = 'colinfritzwork@gmail.com' #github account username for account containing the repo
account_password = 'Cougar@2013' #github account password for account containing the repo
repo_path = 'ColinFritzltts/CAN_Controller' #github repo of interest to pull data from in the previously specified account.  

with open(filename, 'w') as f: # context manager to keep file in write while print statements are being executed 

	sys.stdout = f #sys.stdout gets written to file.  
	g = Github(account_username, account_password) #creates a Github account object 
	r=g.get_repo(repo_path) # retrieves a specific repo from the account 
	print_header(r) # prints to top of text file.  

		
	for pull in r.get_pulls('all'): #loops through all pull requests in the repo represented by r.  
		print_top_border(pull)
		print_author(pull)
		print_reviewers(pull)
		print_ID(pull)
		print_merge_commit_sha(pull)
		print_created(pull)
		print_closed(pull)
		print_description(pull)
		print_review_comments(pull)
		print_conversational_comments(pull)
		print_changed_files(pull)
		print_bottom_border(pull)




		