cask "skilldrop" do
  version "1.2.3"
  sha256 "849eeecd80527325d05bfdb53856a3a0ff84cae57d83f5229827150cf7597c9a"

  url "https://github.com/Blackphi6/SkillDrop/releases/download/v#{version}/SkillDrop-macos-arm64.zip"
  name "SkillDrop"
  desc "Install GitHub Agent Skills into Cursor, Claude Code, and Codex"
  homepage "https://github.com/Blackphi6/SkillDrop"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "SkillDrop.app"

  # 未公証バイナリでも、brew 経由ならここだけで隔離を外せる
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/SkillDrop.app"]
  end

  zap trash: [
    "~/Library/Preferences/local.skilldrop.app.plist",
  ]
end
