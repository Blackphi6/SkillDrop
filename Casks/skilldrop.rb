cask "skilldrop" do
  version "1.2.0"
  sha256 "e2576b94e472357fe0214f936af3e3d0c1b863f09344eaf02bdfe20243eeb315"

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
