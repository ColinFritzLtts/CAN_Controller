"""


"""

from github import Github
import textwrap
import sys 


def print_header(repo_object):
	print('project_name: ' + repo_object.name)

def print_author(pull_req_object):
	print('Author: ' + pull_req_object.user.login)

def print_top_border(pull_req_object):
	print('------------------------- ' + pull.title + ' -------------------------')

def print_reviewers(pull_req_object):
	reviewers= []
	for reviewer in pull_req_object.get_reviews():
		reviewers.append(reviewer.user.login)
	reviewers = set(reviewers)
	print('Reviewers:', *reviewers)

def print_ID(pull_req_object):
	print('ID: ' + str(pull_req_object.id))

def print_created(pull_req_object):
	print('Created: ' + str(pull_req_object.created_at))

def print_closed(pull_req_object):
	print('Closed: ' + str(pull_req_object.closed_at))

def print_description(pull_req_object):
	print('Description: ' + pull_req_object.body)
	print(' ')

def print_review_comments(pull_req_object):
	
	print('Review Comments: ')
	for review_comment in pull_req_object.get_reviews():
		print(review_comment.user.login + ' ')
		comment=textwrap.fill(review_comment.body, width=50)
		comment.encode('unicode_escape')
		print(comment)
		print(' ')
	

def print_conversational_comments(pull_req_object):
	print('Conversational Comments: ')
	for conversational_comment in pull_req_object.get_issue_comments():
		print(conversational_comment.user.login + ' ')
		print(textwrap.fill(conversational_comment.body, 50))
		print(' ')

def print_bottom_border(pull_req_object):
	print('------------------------- ' + pull.title + ' -------------------------')
	print('')
	print('')
	print('')



filename = '/Users/colinfritz/my_repos/CAN_Controller/Review_History' # Location for exporting Pull Request info


with open(filename, 'w') as f:

	sys.stdout = f
	g = Github('colinfritzwork@gmail.com', 'Cougar@2013')
	r=g.get_repo('ColinFritzltts/CAN_Controller')
	print_header(r)

		
	for pull in r.get_pulls('all'):
		print_top_border(pull)
		print_author(pull)
		print_reviewers(pull)
		print_ID(pull)
		print_created(pull)
		print_closed(pull)
		print_description(pull)
		print_review_comments(pull)
		print_conversational_comments(pull)
		print_bottom_border(pull)


		# print('------------------------- ' + pull.title + ' -------------------------')
		# print('Author: ' + pull.user.login)
		# for reviewer in pull.get_reviews():
		# 	reviewers.append(reviewer.user.login)
		# reviewers = set(reviewers)
		# print('Reviewers:', *reviewers)
		# print('ID: ' + str(pull.id))
		# print('Created: ' + str(pull.created_at))
		# print('Closed: ' + str(pull.closed_at))
		# print('Description: ' + pull.body)
		# print('Review Comments:')
		# for review_comment in pull.get_reviews():
		# 	print(review_comment.user.login + ' ')
		# 	print(textwrap.fill(review_comment.body, 50))
		# 	print(' ')
		# print('Conversational Comments: ')
		# for conversational_comment in pull.get_issue_comments():
		# 	print(conversational_comment.user.login + ' ')
		# 	print(textwrap.fill(conversational_comment.body, 50))
		# 	print(' ')

		# print('------------------------- ' + pull.title + ' -------------------------')
		# reviewers = []
		# print('')
		# print('')
		# print('')


		

	print('progresssssjaksahs')