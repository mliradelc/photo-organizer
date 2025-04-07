# GitHub Repository Setup Instructions

Follow these steps to push your local repository to GitHub:

## 1. Create a new repository on GitHub

1. Go to [GitHub](https://github.com/) and sign in to your account
2. Click on the "+" icon in the top right corner and select "New repository"
3. Name your repository (e.g., "photo-organizer")
4. Add a description (optional): "A high-performance shell script tool to organize photos based on EXIF metadata"
5. Choose public or private visibility
6. Do NOT initialize the repository with README, .gitignore, or license (since we already have these files)
7. Click "Create repository"

## 2. Push your local repository to GitHub

After creating the GitHub repository, you'll see instructions for pushing an existing repository.
Run the following commands in your terminal:

```bash
# Make sure you're in the Photo Organizer directory
cd "/home/mliradel/repos/Photo Organizer"

# Add the remote repository
git remote add origin https://github.com/YOUR_USERNAME/photo-organizer.git

# Push the main branch to GitHub
git push -u origin main
```

Replace `YOUR_USERNAME` with your GitHub username.

## 3. Verify your repository on GitHub

1. Navigate to `https://github.com/YOUR_USERNAME/photo-organizer` in your browser
2. Ensure all files are present
3. Check that the README is displayed correctly on the repository homepage

## 4. Enable GitHub Pages (Optional)

If you want to create a simple website for your project:

1. Go to the repository settings
2. Scroll down to the "GitHub Pages" section
3. Select the "main" branch and "/docs" folder as the source
4. Click "Save"

## 5. Set up branch protection (Optional)

To protect your main branch:

1. Go to repository settings
2. Click on "Branches"
3. Add a branch protection rule for the main branch
4. Select options like "Require pull request reviews before merging"
5. Click "Create"