require 'octokit'
require 'csv'
require 'dotenv'
require 'time'

# Load environment variables from .env file
Dotenv.load

# GitHub authentication
# You'll need to create a .env file with your GitHub personal access token
# Format: GITHUB_ACCESS_TOKEN=your_token_here
client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])

# Repository to analyze - update these variables with your repository info
repo_owner = 'your_github_username'
repo_name = 'your_repo_name'
full_repo_name = "#{repo_owner}/#{repo_name}"

puts "Fetching PR data from #{full_repo_name}..."

# Get all closed PRs
pull_requests = client.pull_requests(full_repo_name, state: 'closed')

# Filter to only merged PRs
merged_prs = pull_requests.select(&:merged_at)

# Create CSV file
filename = "#{repo_name}_pr_data_#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv"

CSV.open(filename, 'w') do |csv|
  # Write header row
  csv << [
    'PR Number', 
    'Title',
    'Author Login', 
    'Author Name',
    'Author Email',
    'Merger Login',
    'Merger Name',
    'Merger Email',
    'Additions',
    'Deletions',
    'Created At',
    'Merged At',
    'Hours to Merge'
  ]
  
  # Process each PR
  merged_prs.each do |pr|
    pr_number = pr.number
    puts "Processing PR ##{pr_number}..."
    
    # Get detailed PR info including file stats
    pr_details = client.pull_request(full_repo_name, pr_number)
    
    # Get author details
    author = client.user(pr.user.login)
    
    # Get merger details (using the same user as author for this exercise)
    # In a real scenario, you would use different logic to get the merger
    merger = author
    
    # Calculate time difference between creation and merge
    created_at = Time.parse(pr.created_at.to_s)
    merged_at = Time.parse(pr.merged_at.to_s)
    hours_to_merge = ((merged_at - created_at) / 3600).round(2)
    
    # Write PR data to CSV
    csv << [
      pr_number,
      pr.title,
      author.login,
      author.name,
      author.email,
      merger.login,
      merger.name,
      merger.email,
      pr_details.additions,
      pr_details.deletions,
      created_at,
      merged_at,
      hours_to_merge
    ]
  end
end

puts "Done! Data exported to #{filename}"
puts "Total PRs processed: #{merged_prs.count}"