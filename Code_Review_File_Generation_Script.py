


from github import Github
import textwrap
import sys 


filename = '/Users/colinfritz/my_repos/CAN_Controller/Review_History' # Location for exporting Pull Request info


with open(filename, 'w') as f:
	sys.stdout = f
	g = Github('colinfritzwork@gmail.com', 'Cougar@2013')
	r=g.get_repo('ColinFritzltts/CAN_Controller')
	print(r.name)
	print(" ")
	reviewers = []
	for pull in r.get_pulls('all'):
		print('------------------------- ' + pull.title + ' -------------------------')
		print('Author: ' + pull.user.login)
		for reviewer in pull.get_reviews():
			reviewers.append(reviewer.user.login)
		reviewers = set(reviewers)
		print('Reviewers:', *reviewers)
		print('ID: ' + str(pull.id))
		print('Created: ' + str(pull.created_at))
		print('Closed: ' + str(pull.closed_at))
		print('Description: ' + pull.body)
		print('Review Comments:')
		for review_comment in pull.get_reviews():
			print(review_comment.user.login + ' ')
			print(textwrap.fill(review_comment.body, 50))
			print(' ')
		print('Conversational Comments: ')
		for conversational_comment in pull.get_issue_comments():
			print(conversational_comment.user.login + ' ')
			print(textwrap.fill(conversational_comment.body, 50))
			print(' ')

		print('------------------------- ' + pull.title + ' -------------------------')
		reviewers = []
		print('')
		print('')
		print('')

		
		

	print('progress')


"""
------Title with jira issue and basic description tag ----------
Author:
Reviewers:
ID:
Created:
Closed:
Description:
Review Comments:
author
	comment with CR:, Approval:, Closing: tags prior to the comment.  
Conversation Comments:

------Title with jira issue and basic description tag ----------
"""